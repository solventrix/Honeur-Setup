import logging
import os
import sys
import time
from typing import List

import click
import docker
import questionary
import requests
from docker.client import DockerClient
from docker.models.containers import Container
from docker.models.networks import Network

from cli.configuration.ConfigurationController import ConfigurationController
from cli.globals import Globals
from cli.registry.registry import Registry
from cli.therapeutic_area.therapeutic_area import TherapeuticArea
from cli.configuration.DockerClientFacade import DockerClientFacade
from cli.pipeline.CustomConceptsUpdatePipeline import CustomConceptsUpdatePipeline

# Init logger
log = logging.getLogger(__name__)
log.addHandler(logging.StreamHandler())
log.setLevel(logging.WARNING)


def get_default_feder8_central_environment() -> str:
    return Globals.get_environment()


def get_docker_client() -> DockerClient:
    try:
        return docker.from_env(timeout=3000)
    except docker.errors.DockerException:
        print('Error while connecting to docker...Is docker running?')
        sys.exit(1)


def get_docker_client_facade(therapeutic_area_info: TherapeuticArea, email, cli_key) -> DockerClientFacade:
    return DockerClientFacade(therapeutic_area_info, email, cli_key)


def get_network_name():
    return "feder8-net"


def run_container(docker_client:DockerClient, image:str, remove:bool, name:str, environment, volumes, detach:bool, show_logs:bool):
    network_name = get_network_name()
    container = docker_client.containers.run(
        image, remove=remove, name=name, environment=environment, network=network_name, volumes=volumes, detach=detach)
    if show_logs:
        for l in container.logs(stream=True):
            print(l.decode('UTF-8'), end='')
    return container


def check_networks_and_create_if_not_exists(docker_client:DockerClient, network_names:List[str]):
    networks:List[Network] = []
    for network_name in network_names:
        existing_network = docker_client.networks.list(filters={"name":network_name})
        if len(existing_network) == 0:
            print(' '.join([network_name,'docker network does not exists.']))
            print(' '.join(['Creating',network_name,'docker network...']))
            networks.append(docker_client.networks.create(network_name, driver="bridge"))
            print(' '.join(['Done creating',network_name,'docker network']))
        else:
            networks.append(existing_network[0])
    return networks


def check_volumes_and_create_if_not_exists(docker_client:DockerClient, volume_names:List[str]):
    volumes:List[Network] = []
    for volume_name in volume_names:
        existing_volume = docker_client.volumes.list(filters={"name":volume_name})
        if len(existing_volume) == 0:
            print(' '.join([volume_name,'docker volume does not exists.']))
            print(' '.join(['Creating',volume_name,'docker volume...']))
            volumes.append(docker_client.volumes.create(volume_name))
            print(' '.join(['Done creating',volume_name,'docker volume']))
        else:
            volumes.append(existing_volume[0])
    return volumes


def check_containers_and_remove_if_not_exists(docker_client: DockerClient,
                                              therapeutic_area_info: TherapeuticArea,
                                              container_names: List[str]):
    for container_name in container_names:
        try:
            container = docker_client.containers.get(container_name)
            container_image_name_tag = container.image.tags[0]
            print(f'{container_name} is running.')
            print(f'Removing {container_name} container...')
            container.stop()
            container.remove(v=True)
            print(f'Done removing {container_name} container...')
            cleanup_images(docker_client=docker_client,
                           therapeutic_area_info=therapeutic_area_info,
                           constraint=container_image_name_tag)
        except:
            logging.debug("check_containers_and_remove_if_not_exists failed")

def ta_specific_docker_network_exists(docker_client: DockerClient):
    for therapeutic_area_key in Globals.therapeutic_areas.keys():
        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area_key]
        if therapeutic_area_info.name != 'feder8':
            try:
                therapeutic_area_network = docker_client.networks.get(therapeutic_area_info.name + '-net')
                return True
            except docker.errors.NotFound:
                pass
    return False

def validate_correct_docker_network(docker_client: DockerClient):
    if ta_specific_docker_network_exists(docker_client):
        print("We notice that you have an outdated setup installed. This seperate script is not compatible with this older version of your setup. Please run the full installer to update all components. You can follow the installation instruction at https://github.com/solventrix/Honeur-Setup/tree/release/1.10/local-installation/helper-scripts#installation-instruction")
        sys.exit(1)


def pull_image(docker_client:DockerClient, registry:Registry, image:str, email:str, cli_key:str):
    print(f'Pulling image {image} ...')
    try:
        docker_client.login(username=email, password=cli_key, registry=registry.registry_url, reauth=True)
    except docker.errors.APIError:
        print('Failed to pull image. Are the correct email and CLI Key provided?')
        sys.exit(1)
    docker_client.images.pull(image)
    print(f'Done pulling image {image}')


def wait_for_healthy_container(docker_client:DockerClient, container:Container, interval:int, timeout:int):
    print(' '.join(['Waiting for', container.name, 'to become healthy...']))
    now = time.time()
    until = now + timeout
    while docker_client.api.inspect_container(container.name)['State']['Health']['Status'] != 'healthy':
        now = time.time()
        if now + interval >= until:
            print(' '.join(['Took too long for', container.name, 'to become healthy']))
            return False
        time.sleep(interval)
    print(' '.join([container.name, 'is healthy']))
    return True


def get_or_create_network(docker_client:DockerClient, therapeutic_area_info):
    network_name = get_network_name()
    try:
        network = docker_client.networks.get(network_name)
    except docker.errors.NotFound:
        log.info(f"Create network {network_name}")
        network = docker_client.networks.create(network_name, check_duplicate=True)
    return network


def add_docker_sock_volume_mapping(volumes: dict):
    is_windows = os.getenv('IS_WINDOWS', 'false') == 'true'
    is_mac = os.getenv('IS_MAC', 'false') == 'true'

    if is_mac or is_windows:
        volumes['/var/run/docker.sock.raw'] = {
            'bind': '/var/run/docker.sock',
            'mode': 'rw'
        }
    else:
        volumes['/var/run/docker.sock'] = {
            'bind': '/var/run/docker.sock',
            'mode': 'rw'
        }
    return volumes


def connect_install_container_to_network(docker_client: DockerClient, therapeutic_area_info):
    ta_network = get_or_create_network(docker_client, therapeutic_area_info)
    install_container = docker_client.containers.get("feder8-installer")
    try:
        ta_network.connect(install_container)
    except docker.errors.APIError:
        log.debug(f"Unable to connect the install container to the {therapeutic_area_info.name} network")


def update_config_on_config_server(docker_client:DockerClient, email, cli_key, therapeutic_area_info, config_update):
    # pull config update image
    update_configuration_image_name_tag = get_update_configuration_image_name_tag(therapeutic_area_info)
    registry = therapeutic_area_info.registry
    pull_image(docker_client, registry, update_configuration_image_name_tag, email, cli_key)
    # remove old config update container if present
    container_name = 'config-server-update-configuration'
    check_containers_and_remove_if_not_exists(docker_client, therapeutic_area_info, [container_name])
    # run config update container
    print('Updating configuration on config-server...')
    volume_name = 'feder8-config-server'
    run_container(
        docker_client=docker_client,
        image=update_configuration_image_name_tag,
        remove=True,
        name=container_name,
        environment=config_update,
        volumes={
            volume_name: {
                'bind': '/home/feder8/config-repo',
                'mode': 'rw'
            }
        },
        detach=True,
        show_logs=True)
    # refresh config on server
    refresh_config_on_server(docker_client)
    print('Done updating configuration on config-server')


def refresh_config_on_server(docker_client:DockerClient):
    try:
        docker_client.containers.get("local-portal")
        url = 'http://local-portal:8080/portal/actuator/refresh'
        requests.post(url)
    except docker.errors.NotFound:
        log.debug("Local portal container not found")
    except Exception:
        log.debug("Config could not be refreshed on server")


def get_image_name_tag(therapeutic_area_info, name, tag):
    registry = therapeutic_area_info.registry
    image_name = '/'.join([registry.registry_url, registry.project, name])
    return ':'.join([image_name, tag])


def get_all_feder8_local_image_name_tags(therapeutic_area_info):
    return [
        get_postgres_image_name_tag(therapeutic_area_info),
        get_config_server_image_name_tag(therapeutic_area_info),
        get_update_configuration_image_name_tag(therapeutic_area_info),
        get_local_portal_image_name_tag(therapeutic_area_info),
        get_user_mgmt_image_name_tag(therapeutic_area_info),
        get_atlas_image_name_tag(therapeutic_area_info),
        get_webapi_image_name_tag(therapeutic_area_info),
        get_zeppelin_image_name_tag(therapeutic_area_info),
        get_distributed_analytics_r_server_image_name_tag(therapeutic_area_info),
        get_distributed_analytics_remote_image_name_tag(therapeutic_area_info),
        get_feder8_studio_image_name_tag(therapeutic_area_info),
        get_radiant_installer_image_name_tag(therapeutic_area_info),
        get_nginx_image_name_tag(therapeutic_area_info),
        get_vocabulary_update_image_name_tag(therapeutic_area_info),
        get_local_backup_image_name_tag(therapeutic_area_info),
        get_fix_default_privileges_image_name_tag(therapeutic_area_info)
    ]


def get_postgres_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'postgres', '13-omopcdm-5.3.1-webapi-2.9.0-2.0.7')


def get_config_server_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'config-server', '2.0.1')


def get_update_configuration_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'config-server', 'update-configuration-2.0.1')


def get_local_portal_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'local-portal', '2.0.7')


def get_user_mgmt_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'user-mgmt', '2.0.4')


def get_atlas_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'atlas', '2.9.0-2.0.0')


def get_webapi_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'webapi', '2.9.0-2.0.1')


def get_zeppelin_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'zeppelin', '0.8.2-2.0.4')


def get_distributed_analytics_r_server_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'distributed-analytics', 'r-server-2.0.4')


def get_distributed_analytics_remote_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'distributed-analytics', 'remote-2.0.5')


def get_feder8_studio_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'feder8-studio', '2.0.9')


def get_radiant_installer_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'install-radiant', '2.0.0')


def get_task_manager_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'task-manager', '2.0.1')


def get_nginx_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'nginx', '2.0.9')


def get_vocabulary_update_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'postgres', 'pipeline-vocabulary-update-2.0.2')


def get_local_backup_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'backup', '2.0.0')


def get_fix_default_privileges_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'postgres', 'fix-default-permissions-2.0.1')


def get_alpine_image_name_tag():
    return 'alpine:3.15.0'


def get_postgres_9_6_image_name_tag():
    return 'postgres:9.6'


def get_postgres_13_image_name_tag():
    return 'postgres:13'


def get_tianon_postgres_upgrade_9_6_to_13_image_name_tag():
    return 'tianon/postgres-upgrade:9.6-to-13'


def get_configuration(therapeutic_area) -> ConfigurationController:
    current_environment = os.getenv('CURRENT_DIRECTORY', '')
    is_windows = os.getenv('IS_WINDOWS', 'false') == 'true'
    if not therapeutic_area:
        therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()
    return ConfigurationController(therapeutic_area, current_environment, is_windows)


def get_image_repo_credentials(therapeutic_area, email=None, cli_key=None, configuration: ConfigurationController=None):
    if email and cli_key:
        return email, cli_key
    if not configuration:
        configuration = get_configuration(therapeutic_area)
    return configuration.get_image_repo_credentials()


def get_database_connection_details(therapeutic_area, configuration: ConfigurationController=None):
    if not configuration:
        configuration = get_configuration(therapeutic_area)
    return configuration.get_database_connection_details()

def create_or_update_host_folder_with_correct_ownership(directory: str, owner: int, group: int):
    docker_client = get_docker_client()

    alpine_image_tag = get_alpine_image_name_tag()

    print('Create or update folder permissions for ' + directory + ' on host machine ...')

    container = docker_client.containers.run(image=alpine_image_tag,
                                            remove=False,
                                            name='create-update-folder-permissions',
                                            volumes={
                                                directory: {
                                                    'bind': '/opt/folder',
                                                    'mode': 'rw'
                                                }
                                            },
                                            command='ash -c "chown -R ' + str(owner) + ':' + str(group) + ' /opt/folder"',
                                            detach=True)
    for l in container.logs(stream=True):
        print(l.decode('UTF-8'), end='')
    container.stop()
    container.remove(v=True)

    print('Done creating or updating folder permissions for ' + directory + ' on host machine ...')

@click.group()
def init():
    """Initialize command for different components."""
    pass

@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
@click.option('-e', '--email')
@click.option('-k', '--cli-key')
def config_server(therapeutic_area, email, cli_key):
    try:
        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        docker_client = get_docker_client()

        validate_correct_docker_network(docker_client)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        connect_install_container_to_network(docker_client, therapeutic_area_info)

        registry = therapeutic_area_info.registry

        email, cli_key = get_image_repo_credentials(therapeutic_area, email, cli_key)

    except KeyboardInterrupt:
        sys.exit(1)

    feder8_network = get_network_name()
    network_names = [feder8_network]
    volume_names = ['feder8-config-server']
    container_names = ['config-server', 'config-server-update-configuration']

    check_networks_and_create_if_not_exists(docker_client, network_names)
    check_volumes_and_create_if_not_exists(docker_client, volume_names)
    check_containers_and_remove_if_not_exists(docker_client, therapeutic_area_info, container_names)

    config_update = {
        'FEDER8_CONFIG_SERVER_THERAPEUTIC_AREA': therapeutic_area_info.name,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO': registry.registry_url,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-USERNAME': email,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-KEY': cli_key,
        'FEDER8_CENTRAL_SERVICE_OAUTH-ISSUER-URI': 'https://' + therapeutic_area_info.cas_url + "/oidc",
        'FEDER8_CENTRAL_SERVICE_OAUTH-CLIENT-ID': 'feder8-local',
        'FEDER8_CENTRAL_SERVICE_OAUTH-CLIENT-SECRET': 'qoV2hPEWQjz5mRat',
        'FEDER8_CENTRAL_SERVICE_OAUTH-USERNAME': email,
        'FEDER8_CENTRAL_SERVICE_CATALOGUE-BASE-URI': 'https://' + therapeutic_area_info.catalogue_url,
        'FEDER8_CENTRAL_SERVICE_DISTRIBUTED-ANALYTICS-BASE-URI': 'https://' + therapeutic_area_info.distributed_analytics_url,
        'FEDER8_LOCAL_HOST_FEDER8-STUDIO-URL': '${feder8.local.host.portal-url}/' + therapeutic_area_info.name + '-studio',
        'FEDER8_LOCAL_HOST_FEDER8-STUDIO-CONTAINER-URL': 'http://' + therapeutic_area_info.name + '-studio:8080/' + therapeutic_area_info.name + '-studio'
    }

    update_config_on_config_server(docker_client=docker_client,
                                   email=email, cli_key=cli_key,
                                   therapeutic_area_info=therapeutic_area_info,
                                   config_update=config_update)

    config_server_image_tag = get_config_server_image_name_tag(therapeutic_area_info)

    pull_image(docker_client,registry, config_server_image_tag, email, cli_key)

    print('Starting config-server container...')
    container = docker_client.containers.run(
        image=config_server_image_tag,
        name=container_names[0],
        restart_policy={"Name": "always"},
        security_opt=['no-new-privileges'],
        remove=False,
        environment={
            'SERVER_FORWARD_HEADERS_STRATEGY': 'framework',
            'SERVER_SERVLET_CONTEXT_PATH': '/config-server',
            'JDK_JAVA_OPTIONS': "-Dlog4j2.formatMsgNoLookups=true"
        },
        network=network_names[0],
        volumes={
            volume_names[0]: {
                'bind': '/home/feder8/config-repo',
                'mode': 'rw'
            }
        },
        detach=True
    )

    print('Done starting config-server container')

    wait_for_healthy_container(docker_client, container, 5, 120)


@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
@click.option('-e', '--email')
@click.option('-k', '--cli-key')
@click.option('-up', '--user-password')
@click.option('-ap', '--admin-password')
@click.option('-edoh', '--expose-database-on-host')
@click.pass_context
def postgres(ctx, therapeutic_area, email, cli_key, user_password, admin_password, expose_database_on_host):
    try:
        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        docker_client = get_docker_client()

        validate_correct_docker_network(docker_client)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        connect_install_container_to_network(docker_client, therapeutic_area_info)

        registry = therapeutic_area_info.registry

        configuration:ConfigurationController = get_configuration(therapeutic_area)
        if email is None:
            email = configuration.get_configuration('feder8.central.service.image-repo-username')
        if cli_key is None:
            cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')
        if user_password is None:
            user_password = configuration.get_configuration('feder8.local.datasource.password')
        if admin_password is None:
            admin_password = configuration.get_configuration('feder8.local.datasource.admin-password')

        if expose_database_on_host is None:
            expose_database_on_host = questionary.confirm("Do you want to expose the postgres database on your host through port 5444?").unsafe_ask()
    except KeyboardInterrupt:
        sys.exit(1)

    feder8_network = get_network_name()
    network_names = [feder8_network]
    volume_names = ['pgdata', 'shared', 'feder8-config-server']
    container_names = ['postgres', 'config-server-update-configuration']

    check_networks_and_create_if_not_exists(docker_client, network_names)
    check_volumes_and_create_if_not_exists(docker_client, volume_names)
    check_containers_and_remove_if_not_exists(docker_client, therapeutic_area_info, container_names)

    config_update = {
        'FEDER8_CONFIG_SERVER_THERAPEUTIC_AREA': therapeutic_area_info.name,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO': registry.registry_url,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-USERNAME': email,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-KEY': cli_key,
        'FEDER8_LOCAL_DATASOURCE_HOST': container_names[0],
        'FEDER8_LOCAL_DATASOURCE_NAME': 'OHDSI',
        'FEDER8_LOCAL_DATASOURCE_PORT': '5432',
        'FEDER8_LOCAL_DATASOURCE_USERNAME': therapeutic_area_info.name,
        'FEDER8_LOCAL_DATASOURCE_PASSWORD': user_password,
        'FEDER8_LOCAL_DATASOURCE_ADMIN-USERNAME': therapeutic_area_info.name + '_admin',
        'FEDER8_LOCAL_DATASOURCE_ADMIN-PASSWORD': admin_password,
    }

    update_config_on_config_server(docker_client=docker_client,
                                   email=email, cli_key=cli_key,
                                   therapeutic_area_info=therapeutic_area_info,
                                   config_update=config_update)

    postgres_image_name_tag = get_postgres_image_name_tag(therapeutic_area_info)

    pull_image(docker_client,registry, postgres_image_name_tag, email, cli_key)

    print('Starting postgres container...')

    ports = {}
    if expose_database_on_host:
        ports['5432/tcp'] = 5444

    container = docker_client.containers.run(
        image=postgres_image_name_tag,
        name=container_names[0],
        ports=ports,
        restart_policy={"Name": "always"},
        security_opt=['no-new-privileges'],
        remove=False,
        environment={},
        network=network_names[0],
        volumes={
            volume_names[0]: {
                'bind': '/var/lib/postgresql/data',
                'mode': 'rw'
            },
            volume_names[1]: {
                'bind': '/var/lib/postgresql/envfileshared',
                'mode': 'rw'
            }
        },
        detach=True
    )

    print('Done starting postgres container')

    wait_for_healthy_container(docker_client, container, 5, 120)

    ctx.invoke(fix_default_privileges, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key)




@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
@click.option('-e', '--email')
@click.option('-k', '--cli-key')
@click.option('-h', '--host')
@click.option('-u', '--username')
@click.option('-p', '--password')
@click.option('-edr', '--enable-docker-runner')
def local_portal(therapeutic_area, email, cli_key, host, username, password, enable_docker_runner):
    try:
        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?",
                                                  choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        docker_client = get_docker_client()

        validate_correct_docker_network(docker_client)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        central_portal_uri = f"https://{therapeutic_area_info.portal_url}"

        connect_install_container_to_network(docker_client, therapeutic_area_info)

        registry = therapeutic_area_info.registry

        configuration:ConfigurationController = get_configuration(therapeutic_area)
        if email is None:
            email = configuration.get_configuration('feder8.central.service.image-repo-username')
        if cli_key is None:
            cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')
        if host is None:
            host = configuration.get_configuration('feder8.local.host.name')
        if username is None:
            username = configuration.get_configuration('feder8.local.security.user-mgmt-username')
        if password is None:
            password = configuration.get_configuration('feder8.local.security.user-mgmt-password')
        if enable_docker_runner is None:
            enable_docker_runner = questionary.confirm("Do you want to enable support for Docker based analysis scripts?").unsafe_ask()
        if enable_docker_runner:
            enable_docker_runner_string = 'true'
        else:
            enable_docker_runner_string = 'false'
    except KeyboardInterrupt:
        sys.exit(1)

    feder8_network = get_network_name()
    network_names = [feder8_network]
    volume_names = ['shared', 'feder8-config-server']
    container_names = ['local-portal', 'config-server-update-configuration']

    check_networks_and_create_if_not_exists(docker_client, network_names)
    check_volumes_and_create_if_not_exists(docker_client, volume_names)
    check_containers_and_remove_if_not_exists(docker_client, therapeutic_area_info, container_names)

    config_update = {
        'FEDER8_CONFIG_SERVER_THERAPEUTIC_AREA': therapeutic_area_info.name,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO': registry.registry_url,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-USERNAME': email,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-KEY': cli_key,
        'FEDER8_CENTRAL_SERVICE_PORTAL-BASE-URI': central_portal_uri,
        'FEDER8_LOCAL_HOST_NAME': host,
        'FEDER8_LOCAL_SECURITY_USER-MGMT-USERNAME': username,
        'FEDER8_LOCAL_SECURITY_USER-MGMT-PASSWORD': password
    }

    update_config_on_config_server(docker_client=docker_client,
                                   email=email, cli_key=cli_key,
                                   therapeutic_area_info=therapeutic_area_info,
                                   config_update=config_update)

    local_portal_image_name_tag = get_local_portal_image_name_tag(therapeutic_area_info)

    pull_image(docker_client,registry, local_portal_image_name_tag, email, cli_key)

    print('Starting local-portal container...')
    socket_gid = os.stat("/var/run/docker.sock").st_gid
    volumes={
            volume_names[0]: {
                'bind': '/var/lib/shared',
                'mode': 'ro'
            },
            volume_names[1]: {
                'bind': '/home/feder8/config-repo',
                'mode': 'rw'
            }
        }
    volumes = add_docker_sock_volume_mapping(volumes)

    container = docker_client.containers.run(
        image=local_portal_image_name_tag,
        name=container_names[0],
        restart_policy={"Name": "always"},
        security_opt=['no-new-privileges'],
        remove=False,
        environment={
            'FEDER8_THERAPEUTIC_AREA_NAME': therapeutic_area_info.name,
            'FEDER8_THERAPEUTIC_AREA_LIGHT_THEME_COLOR': therapeutic_area_info.light_theme,
            'FEDER8_THERAPEUTIC_AREA_DARK_THEME_COLOR': therapeutic_area_info.dark_theme,
            'FEDER8_CONFIG_SERVER_USERNAME': 'root',
            'FEDER8_CONFIG_SERVER_HOST': 'config-server',
            'FEDER8_CONFIG_SERVER_PORT': '8080',
            'FEDER8_CONFIG_SERVER_CONTEXT_PATH': '/config-server',
            'FEDER8_LOCAL_ADMIN_USERNAME': username,
            'FEDER8_LOCAL_ADMIN_PASSWORD': password,
            'FEDER8_ENABLE_DOCKER_RUNNER': enable_docker_runner_string,
            'FEDER8_CENTRAL_SERVICE_ENVIRONMENT': get_default_feder8_central_environment(),
            'SERVER_FORWARD_HEADERS_STRATEGY': 'framework',
            'SERVER_SERVLET_CONTEXT_PATH': '/portal',
            'JDK_JAVA_OPTIONS': "-Dlog4j2.formatMsgNoLookups=true"
        },
        network=network_names[0],
        volumes=volumes,
        group_add=[socket_gid, 0],
        detach=True
    )

    print('Done starting local-portal container')

    wait_for_healthy_container(docker_client, container, 5, 120)

@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
@click.option('-e', '--email')
@click.option('-k', '--cli-key')
@click.option('-h', '--host')
@click.option('-es', '--enable-ssl')
@click.option('-cd', '--certificate-directory')
@click.option('-s', '--security-method', type=click.Choice(['None', 'JDBC', 'LDAP']))
@click.option('-lu', '--ldap-url')
@click.option('-ldn', '--ldap-dn')
@click.option('-lbdn', '--ldap-base-dn')
@click.option('-lsu', '--ldap-system-username')
@click.option('-lsp', '--ldap-system-password')
def atlas_webapi(therapeutic_area, email, cli_key, host, enable_ssl, certificate_directory, security_method, ldap_url, ldap_dn, ldap_base_dn, ldap_system_username, ldap_system_password):
    try:
        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        docker_client = get_docker_client()

        validate_correct_docker_network(docker_client)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        connect_install_container_to_network(docker_client, therapeutic_area_info)

        registry = therapeutic_area_info.registry

        configuration:ConfigurationController = get_configuration(therapeutic_area)
        if email is None:
            email = configuration.get_configuration('feder8.central.service.image-repo-username')
        if cli_key is None:
            cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')

        if host is None:
            host = configuration.get_configuration('feder8.local.host.name')

        if enable_ssl is None:
            enable_ssl = questionary.confirm('Do you want to enable HTTPS? Before you can enable HTTPS support, you should have a folder containing a public key certificate file named "feder8.crt" and a private key file named "feder8.key".').unsafe_ask()
        if enable_ssl:
            if certificate_directory is None:
                certificate_directory = configuration.get_configuration('feder8.local.host.ssl-cert-directory')

        if security_method is None:
            security_method = configuration.get_configuration('feder8.local.security.security-method')

        if security_method == 'LDAP':
            if ldap_url is None:
                ldap_url = configuration.get_configuration('feder8.local.security.ldap-url')
            if ldap_dn is None:
                ldap_dn = configuration.get_configuration('feder8.local.security.ldap-dn')
            if ldap_base_dn is None:
                ldap_base_dn = configuration.get_configuration('feder8.local.security.ldap-base-dn')
            if ldap_system_username is None:
                ldap_system_username = configuration.get_configuration('feder8.local.security.ldap-system-username')
            if ldap_system_password is None:
                ldap_system_password = configuration.get_configuration('feder8.local.security.ldap-system-password')
    except KeyboardInterrupt:
        sys.exit(1)

    feder8_network = get_network_name()
    network_names = [feder8_network]
    volume_names = ['shared', 'feder8-config-server']
    container_names = ['webapi', 'atlas', 'config-server-update-configuration']

    check_networks_and_create_if_not_exists(docker_client, network_names)
    check_volumes_and_create_if_not_exists(docker_client, volume_names)
    check_containers_and_remove_if_not_exists(docker_client, therapeutic_area_info, container_names)

    config_update = {
        'FEDER8_CONFIG_SERVER_THERAPEUTIC_AREA': therapeutic_area_info.name,
        'FEDER8_LOCAL_HOST_NAME': host,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO': registry.registry_url,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-USERNAME': email,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-KEY': cli_key,
        'FEDER8_LOCAL_HOST_SSL-CERT-DIRECTORY': certificate_directory
    }
    if security_method == 'None':
        config_update['FEDER8_LOCAL_SECURITY_SECURITY-METHOD'] = 'None'
    else:
        if security_method == 'LDAP':
            config_update['FEDER8_LOCAL_SECURITY_SECURITY-METHOD'] = 'LDAP'
            config_update['FEDER8_LOCAL_SECURITY_LDAP-URL'] = ldap_url
            config_update['FEDER8_LOCAL_SECURITY_LDAP-DN'] = ldap_dn
            config_update['FEDER8_LOCAL_SECURITY_LDAP-BASE-DN'] = ldap_base_dn
            config_update['FEDER8_LOCAL_SECURITY_LDAP-SYSTEM-USERNAME'] = ldap_system_username
            config_update['FEDER8_LOCAL_SECURITY_LDAP-SYSTEM-PASSWORD'] = ldap_system_password
        else:
            config_update['FEDER8_LOCAL_SECURITY_SECURITY-METHOD'] = 'JDBC'

    update_config_on_config_server(docker_client=docker_client,
                                   email=email, cli_key=cli_key,
                                   therapeutic_area_info=therapeutic_area_info,
                                   config_update=config_update)

    webapi_image_name_tag = get_webapi_image_name_tag(therapeutic_area_info)

    pull_image(docker_client, registry, webapi_image_name_tag, email, cli_key)

    print('Starting WebAPI container...')
    environment_variables = {
        'DB_HOST': 'postgres',
        'FEDER8_WEBAPI_CENTRAL': 'false',
        'SERVER_CONTEXT_PATH': '/webapi',
        'SERVER_USE_FORWARD_HEADERS': 'true',
        'JAVA_OPTS': "-Dlog4j2.formatMsgNoLookups=true"
    }
    if security_method == 'None':
        environment_variables['FEDER8_WEBAPI_SECURE'] = 'false'
    else:
        environment_variables['FEDER8_WEBAPI_SECURE'] = 'true'
        if security_method == 'LDAP':
            environment_variables['FEDER8_WEBAPI_AUTH_METHOD'] = 'ldap'
            environment_variables['FEDER8_WEBAPI_LDAP_URL'] = ldap_url
            environment_variables['FEDER8_WEBAPI_LDAP_DN'] = ldap_dn
            environment_variables['FEDER8_WEBAPI_LDAP_BASEDN'] = ldap_base_dn
            environment_variables['FEDER8_WEBAPI_LDAP_SYSTEM_USERNAME'] = ldap_system_username
            environment_variables['FEDER8_WEBAPI_LDAP_SYSTEM_PASSWORD'] = ldap_system_password
        else:
            environment_variables['FEDER8_WEBAPI_AUTH_METHOD'] = 'jdbc'

    container = docker_client.containers.run(
        image=webapi_image_name_tag,
        name=container_names[0],
        restart_policy={"Name": "always"},
        security_opt=['no-new-privileges'],
        remove=False,
        environment=environment_variables,
        network=network_names[0],
        volumes={
            volume_names[0]: {
                'bind': '/var/lib/shared',
                'mode': 'ro'
            }
        },
        detach=True
    )

    print('Done starting WebAPI container')

    wait_for_healthy_container(docker_client, container, 5, 120)

    atlas_image_name_tag = get_atlas_image_name_tag(therapeutic_area_info)

    pull_image(docker_client,registry, atlas_image_name_tag, email, cli_key)

    print('Starting Atlas container...')
    environment_variables = {
        'FEDER8_ATLAS_CENTRAL': 'false',
        'FEDER8_WEBAPI_URL': '/webapi/'
    }

    if security_method == 'None':
        environment_variables['FEDER8_ATLAS_SECURE'] = 'false'
        environment_variables['FEDER8_ATLAS_LDAP_ENABLED'] = 'false'
    else:
        environment_variables['FEDER8_ATLAS_SECURE'] = 'true'
        if security_method == 'LDAP':
            environment_variables['FEDER8_ATLAS_LDAP_ENABLED'] = 'true'
        else:
            environment_variables['FEDER8_ATLAS_LDAP_ENABLED'] = 'false'
    container = docker_client.containers.run(
        image=atlas_image_name_tag,
        name=container_names[1],
        restart_policy={"Name": "always"},
        security_opt=['no-new-privileges'],
        remove=False,
        environment=environment_variables,
        network=network_names[0],
        volumes={},
        detach=True
    )

    print('Done starting Atlas container')

    wait_for_healthy_container(docker_client, container, 5, 120)


@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
@click.option('-e', '--email')
@click.option('-k', '--cli-key')
@click.option('-ld', '--log-directory')
@click.option('-nd', '--notebook-directory')
@click.option('-s', '--security-method', type=click.Choice(['None', 'JDBC', 'LDAP']))
@click.option('-lu', '--ldap-url')
@click.option('-ldn', '--ldap-dn')
@click.option('-lbdn', '--ldap-base-dn')
@click.option('-lsu', '--ldap-system-username')
@click.option('-lsp', '--ldap-system-password')
def zeppelin(therapeutic_area, email, cli_key, log_directory, notebook_directory, security_method, ldap_url, ldap_dn, ldap_base_dn, ldap_system_username, ldap_system_password):
    try:
        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        docker_client = get_docker_client()

        validate_correct_docker_network(docker_client)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        connect_install_container_to_network(docker_client, therapeutic_area_info)

        registry = therapeutic_area_info.registry

        configuration:ConfigurationController = get_configuration(therapeutic_area)
        if email is None:
            email = configuration.get_configuration('feder8.central.service.image-repo-username')
        if cli_key is None:
            cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')

        if log_directory is None:
            log_directory = configuration.get_configuration('feder8.local.host.zeppelin-log-directory')

        if notebook_directory is None:
            notebook_directory = configuration.get_configuration('feder8.local.host.zeppelin-notebook-directory')

        if security_method is None:
            security_method = configuration.get_configuration('feder8.local.security.security-method')

        if security_method == 'LDAP':
            if ldap_url is None:
                ldap_url = configuration.get_configuration('feder8.local.security.ldap-url')
            if ldap_dn is None:
                ldap_dn = configuration.get_configuration('feder8.local.security.ldap-dn')
            if ldap_base_dn is None:
                ldap_base_dn = configuration.get_configuration('feder8.local.security.ldap-base-dn')
            if ldap_system_username is None:
                ldap_system_username = configuration.get_configuration('feder8.local.security.ldap-system-username')
            if ldap_system_password is None:
                ldap_system_password = configuration.get_configuration('feder8.local.security.ldap-system-password')
    except KeyboardInterrupt:
        sys.exit(1)

    feder8_network = get_network_name()
    network_names = [feder8_network]
    volume_names = ['feder8-data', 'shared', 'feder8-config-server']
    container_names = ['zeppelin', 'config-server-update-configuration']

    check_networks_and_create_if_not_exists(docker_client, network_names)
    check_volumes_and_create_if_not_exists(docker_client, volume_names)
    check_containers_and_remove_if_not_exists(docker_client, therapeutic_area_info, container_names)

    config_update = {
        'FEDER8_CONFIG_SERVER_THERAPEUTIC_AREA': therapeutic_area_info.name,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO': registry.registry_url,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-USERNAME': email,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-KEY': cli_key,
        'FEDER8_LOCAL_HOST_ZEPPELIN-LOG-DIRECTORY': log_directory,
        'FEDER8_LOCAL_HOST_ZEPPELIN-NOTEBOOK-DIRECTORY': notebook_directory
    }
    if security_method == 'None':
        config_update['FEDER8_LOCAL_SECURITY_SECURITY-METHOD'] = 'None'
    else:
        if security_method == 'LDAP':
            config_update['FEDER8_LOCAL_SECURITY_SECURITY-METHOD'] = 'LDAP'
            config_update['FEDER8_LOCAL_SECURITY_LDAP-URL'] = ldap_url
            config_update['FEDER8_LOCAL_SECURITY_LDAP-DN'] = ldap_dn
            config_update['FEDER8_LOCAL_SECURITY_LDAP-BASE-DN'] = ldap_base_dn
            config_update['FEDER8_LOCAL_SECURITY_LDAP-SYSTEM-USERNAME'] = ldap_system_username
            config_update['FEDER8_LOCAL_SECURITY_LDAP-SYSTEM-PASSWORD'] = ldap_system_password
        else:
            config_update['FEDER8_LOCAL_SECURITY_SECURITY-METHOD'] = 'JDBC'

    update_config_on_config_server(docker_client=docker_client,
                                   email=email, cli_key=cli_key,
                                   therapeutic_area_info=therapeutic_area_info,
                                   config_update=config_update)

    zeppelin_image_name_tag = get_zeppelin_image_name_tag(therapeutic_area_info)

    pull_image(docker_client, registry, zeppelin_image_name_tag, email, cli_key)

    print('Starting Zeppelin container...')
    environment_variables = {
        'ZEPPELIN_NOTEBOOK_DIR': '/notebook',
        'FEDER8_WEBAPI_CENTRAL': 'false',
        'ZEPPELIN_SERVER_CONTEXT_PATH': '/zeppelin',
        'JAVA_OPTS': "-Dlog4j2.formatMsgNoLookups=true"
    }
    if security_method == 'LDAP':
        environment_variables['ZEPPELIN_SECURITY'] = 'ldap'
        environment_variables['LDAP_URL'] = ldap_url
        environment_variables['LDAP_DN'] = ldap_dn
        environment_variables['LDAP_BASE_DN'] = ldap_base_dn
    elif security_method == 'JDBC':
        environment_variables['ZEPPELIN_SECURITY'] = 'jdbc'
        environment_variables['LDAP_URL'] = 'ldap://localhost:389'
        environment_variables['LDAP_DN'] = 'dc=example,dc=org'
        environment_variables['LDAP_BASE_DN'] = 'cn=\{0\},dc=example,dc=org'

    container = docker_client.containers.run(
        image=zeppelin_image_name_tag,
        name=container_names[0],
        restart_policy={"Name": "always"},
        security_opt=['no-new-privileges'],
        remove=False,
        environment=environment_variables,
        network=network_names[0],
        volumes={
            volume_names[1]: {
                'bind': '/var/lib/shared',
                'mode': 'ro'
            },
            log_directory: {
                'bind': '/logs',
                'mode': 'rw'
            },
            notebook_directory: {
                'bind': '/notebook',
                'mode': 'rw'
            },
            volume_names[0]: {
                'bind': '/usr/local/src/datafiles',
                'mode': 'rw'
            }
        },
        detach=True
    )

    print('Done starting Zeppelin container')

    wait_for_healthy_container(docker_client, container, 5, 120)


@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
@click.option('-e', '--email')
@click.option('-k', '--cli-key')
@click.option('-u', '--username')
@click.option('-p', '--password')
def user_management(therapeutic_area, email, cli_key, username, password):
    try:
        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        docker_client = get_docker_client()

        validate_correct_docker_network(docker_client)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        connect_install_container_to_network(docker_client, therapeutic_area_info)

        registry = therapeutic_area_info.registry

        configuration:ConfigurationController = get_configuration(therapeutic_area)

        security_method = configuration.get_configuration('feder8.local.security.security-method')
        if security_method == 'None':
            print('Local security is not enabled.')
            return

        if email is None:
            email = configuration.get_configuration('feder8.central.service.image-repo-username')
        if cli_key is None:
            cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')

        if username is None:
            username = configuration.get_configuration('feder8.local.security.user-mgmt-username')

        if password is None:
            password = configuration.get_configuration('feder8.local.security.user-mgmt-password')
    except KeyboardInterrupt:
        sys.exit(1)

    feder8_network = get_network_name()
    network_names = [feder8_network]
    volume_names = ['shared', 'feder8-config-server']
    container_names = ['user-mgmt', 'config-server-update-configuration']

    check_networks_and_create_if_not_exists(docker_client, network_names)
    check_volumes_and_create_if_not_exists(docker_client, volume_names)
    check_containers_and_remove_if_not_exists(docker_client, therapeutic_area_info, container_names)

    config_update = {
        'FEDER8_CONFIG_SERVER_THERAPEUTIC_AREA': therapeutic_area_info.name,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO': registry.registry_url,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-USERNAME': email,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-KEY': cli_key,
        'FEDER8_LOCAL_SECURITY_USER-MGMT-USERNAME': username,
        'FEDER8_LOCAL_SECURITY_USER-MGMT-PASSWORD': password
    }

    update_config_on_config_server(docker_client=docker_client,
                                   email=email, cli_key=cli_key,
                                   therapeutic_area_info=therapeutic_area_info,
                                   config_update=config_update)

    user_management_image_name_tag = get_user_mgmt_image_name_tag(therapeutic_area_info)

    pull_image(docker_client, registry, user_management_image_name_tag, email, cli_key)

    print('Starting User Management container...')
    environment_variables = {
        'HONEUR_THERAPEUTIC_AREA_NAME': therapeutic_area_info.name,
        'HONEUR_THERAPEUTIC_AREA_LIGHT_THEME_COLOR': therapeutic_area_info.light_theme,
        'HONEUR_THERAPEUTIC_AREA_DARK_THEME_COLOR': therapeutic_area_info.dark_theme,
        'HONEUR_USERMGMT_USERNAME': username,
        'HONEUR_USERMGMT_PASSWORD': password,
        'DATASOURCE_DRIVER_CLASS_NAME': 'org.postgresql.Driver',
        'DATASOURCE_URL': 'jdbc:postgresql://postgres:5432/OHDSI?currentSchema=webapi',
        'WEBAPI_ADMIN_USERNAME': 'ohdsi_admin_user',
        'FEDER8_THERAPEUTIC_AREA_FAVICON_LOCATION': '/images/' + therapeutic_area_info.name + '-favicon.ico',
        'FEDER8_THERAPEUTIC_AREA_LOGO_LOCATION': '/images/' + therapeutic_area_info.name + '-logo.png',
        'JDK_JAVA_OPTIONS': "-Dlog4j2.formatMsgNoLookups=true"
    }
    container = docker_client.containers.run(
        image=user_management_image_name_tag,
        name=container_names[0],
        restart_policy={"Name": "always"},
        security_opt=['no-new-privileges'],
        remove=False,
        environment=environment_variables,
        network=network_names[0],
        volumes={
            volume_names[0]: {
                'bind': '/var/lib/shared',
                'mode': 'ro'
            }
        },
        detach=True
    )

    print('Done starting User Management container')

    wait_for_healthy_container(docker_client, container, 5, 120)

@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
@click.option('-e', '--email')
@click.option('-k', '--cli-key')
@click.option('-s', '--security-method', type=click.Choice(['None', 'JDBC', 'LDAP']))
@click.option('-au', '--admin-username')
@click.option('-ap', '--admin-password')
@click.option('-fsd', '--feder8-studio-directory')
@click.option('-rud', '--rstudio-upload-dir')
@click.option('-vud', '--vscode-upload-dir')
def task_manager(therapeutic_area, email, cli_key, feder8_studio_directory, security_method, admin_username, admin_password, rstudio_upload_dir, vscode_upload_dir):
    try:
        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        docker_client = get_docker_client()

        validate_correct_docker_network(docker_client)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        connect_install_container_to_network(docker_client, therapeutic_area_info)

        registry = therapeutic_area_info.registry

        configuration:ConfigurationController = get_configuration(therapeutic_area)
        if email is None:
            email = configuration.get_configuration('feder8.central.service.image-repo-username')
        if cli_key is None:
            cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')

        if feder8_studio_directory is None:
            feder8_studio_directory = configuration.get_configuration('feder8.local.host.feder8-studio-directory')

        if rstudio_upload_dir is None:
            rstudio_upload_dir = 'r-scripts'
        if vscode_upload_dir is None:
            vscode_upload_dir = 'scripts'

        if security_method is None:
            security_method = configuration.get_configuration('feder8.local.security.security-method')

        if security_method == 'LDAP':
            if admin_username is None:
                admin_username = configuration.get_configuration('feder8.local.security.user-mgmt-username')
            if admin_password is None:
                admin_password = configuration.get_configuration('feder8.local.security.user-mgmt-password')
    except KeyboardInterrupt:
        sys.exit(1)

    feder8_network = get_network_name()
    network_names = [feder8_network]
    volume_names = ['feder8-config-server']
    container_names = ['task-manager', 'config-server-update-configuration']

    check_networks_and_create_if_not_exists(docker_client, network_names)
    check_volumes_and_create_if_not_exists(docker_client, volume_names)
    check_containers_and_remove_if_not_exists(docker_client, therapeutic_area_info, container_names)

    config_update = {
        'FEDER8_CONFIG_SERVER_THERAPEUTIC_AREA': therapeutic_area_info.name,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO': registry.registry_url,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-USERNAME': email,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-KEY': cli_key,
    }
    if security_method == 'None':
        config_update['FEDER8_LOCAL_SECURITY_SECURITY-METHOD'] = 'None'
    else:
        if security_method == 'LDAP':
            config_update['FEDER8_LOCAL_SECURITY_SECURITY-METHOD'] = 'LDAP'
            config_update['FEDER8_LOCAL_SECURITY_USER-MGMT-USERNAME'] = admin_username,
            config_update['FEDER8_LOCAL_SECURITY_USER-MGMT-PASSWORD'] = admin_password
        else:
            config_update['FEDER8_LOCAL_SECURITY_SECURITY-METHOD'] = 'JDBC'

    update_config_on_config_server(docker_client=docker_client,
                                   email=email, cli_key=cli_key,
                                   therapeutic_area_info=therapeutic_area_info,
                                   config_update=config_update)

    task_manager_image_name_tag = get_task_manager_image_name_tag(therapeutic_area_info)

    pull_image(docker_client, registry, task_manager_image_name_tag, email, cli_key)

    print('Starting Task Manager container...')
    environment_variables = {
        'SPRING_PROFILES_ACTIVE': 'local',
        'FEDER8_CONFIG_SERVER_USERNAME': 'root',
        'FEDER8_CONFIG_SERVER_HOST': 'config-server',
        'FEDER8_CONFIG_SERVER_PORT': '8080',
        'FEDER8_CONFIG_SERVER_CONTEXT_PATH': '/config-server',
        'LOCAL_CONFIGURATION_CLIENT_HOST': 'local-portal',
        'LOCAL_CONFIGURATION_CLIENT_PORT': '8080',
        'LOCAL_CONFIGURATION_CLIENT_BIND': 'portal',
        'LOCAL_CONFIGURATION_CLIENT_API': 'api',
        'DOCKER_RUNNER_CLIENT_HOST': 'local-portal',
        'DOCKER_RUNNER_CLIENT_PORT': '8080',
        'DOCKER_RUNNER_CLIENT_CONTEXT_PATH': 'portal',
        'FEDER8_IS_CENTRAL': 'false',
        'SERVER_SERVLET_CONTEXT_PATH': '/task-manager',
        'FEDER8_THERAPEUTIC_AREA_NAME': therapeutic_area_info.name,
        'FEDER8_THERAPEUTIC_AREA_FAVICON_LOCATION': '/images/' + therapeutic_area_info.name + '-favicon.ico',
        'FEDER8_THERAPEUTIC_AREA_LOGO_LOCATION': '/images/' + therapeutic_area_info.name + '-logo.png',
        'FEDER8_THERAPEUTIC_AREA_LIGHT_THEME_COLOR': therapeutic_area_info.light_theme,
        'FEDER8_THERAPEUTIC_AREA_DARK_THEME_COLOR': therapeutic_area_info.dark_theme
    }
    if security_method == 'LDAP':
        environment_variables['FEDER8_SECURITY_ENABLED'] = 'true'
        environment_variables['FEDER8_IN_MEMORY_AUTH_ENABLED'] = 'true'
        environment_variables['FEDER8_IN_MEMORY_AUTH_USERNAME'] = admin_username
        environment_variables['FEDER8_IN_MEMORY_AUTH_PASSWORD'] = admin_password
    elif security_method == 'JDBC':
        environment_variables['FEDER8_SECURITY_ENABLED'] = 'true'
        environment_variables['FEDER8_IN_MEMORY_AUTH_ENABLED'] = 'false'
    else:
        environment_variables['FEDER8_SECURITY_ENABLED'] = 'false'

    studio_directory = feder8_studio_directory + '/sites/' + therapeutic_area_info.name + 'studio'
    create_or_update_host_folder_with_correct_ownership(studio_directory, 54321, 54321)

    container = docker_client.containers.run(
        image=task_manager_image_name_tag,
        name=container_names[0],
        restart_policy={"Name": "always"},
        security_opt=['no-new-privileges'],
        remove=False,
        environment=environment_variables,
        network=network_names[0],
        volumes={
            studio_directory: {
                'bind': '/home/feder8/studio',
                'mode': 'rw'
            }
        },
        detach=True
    )

    print('Done starting Task Manager container')

    wait_for_healthy_container(docker_client, container, 5, 120)


@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
@click.option('-e', '--email')
@click.option('-k', '--cli-key')
@click.option('-o', '--organization')
def distributed_analytics(therapeutic_area, email, cli_key, organization):
    try:
        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        docker_client = get_docker_client()

        validate_correct_docker_network(docker_client)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        connect_install_container_to_network(docker_client, therapeutic_area_info)

        registry = therapeutic_area_info.registry

        configuration:ConfigurationController = get_configuration(therapeutic_area)

        if email is None:
            email = configuration.get_configuration('feder8.central.service.image-repo-username')
        if cli_key is None:
            cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')

        if organization is None:
            organization = questionary.select("Name of organization?", choices=therapeutic_area_info.organizations).unsafe_ask()

    except KeyboardInterrupt:
        sys.exit(1)

    feder8_network = get_network_name()
    network_names = [feder8_network]
    volume_names = ['feder8-data', 'feder8-config-server']
    container_names = ['distributed-analytics-r-server', 'distributed-analytics-remote', 'config-server-update-configuration']

    check_networks_and_create_if_not_exists(docker_client, network_names)
    check_volumes_and_create_if_not_exists(docker_client, volume_names)
    check_containers_and_remove_if_not_exists(docker_client, therapeutic_area_info, container_names)

    config_update = {
        'FEDER8_CONFIG_SERVER_THERAPEUTIC_AREA': therapeutic_area_info.name,
        'FEDER8_LOCAL_ORGANIZATION': organization,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO': registry.registry_url,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-USERNAME': email,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-KEY': cli_key
    }

    update_config_on_config_server(docker_client=docker_client,
                                   email=email, cli_key=cli_key,
                                   therapeutic_area_info=therapeutic_area_info,
                                   config_update=config_update)

    distributed_analytics_r_server_image_name_tag = get_distributed_analytics_r_server_image_name_tag(therapeutic_area_info)

    pull_image(docker_client, registry, distributed_analytics_r_server_image_name_tag, email, cli_key)

    print('Starting Distributed Analytics R Server container...')
    environment_variables = {}
    container = docker_client.containers.run(
        image=distributed_analytics_r_server_image_name_tag,
        name=container_names[0],
        restart_policy={"Name": "always"},
        security_opt=['no-new-privileges'],
        remove=False,
        environment=environment_variables,
        network=network_names[0],
        volumes={
            volume_names[0]: {
                'bind': '/home/feder8/data',
                'mode': 'rw'
            }
        },
        detach=True
    )

    print('Done starting Distributed Analytics R Server container')

    wait_for_healthy_container(docker_client, container, 5, 120)

    distributed_analytics_remote_image_name_tag = get_distributed_analytics_remote_image_name_tag(therapeutic_area_info)

    pull_image(docker_client, registry, distributed_analytics_remote_image_name_tag, email, cli_key)

    print('Starting Distributed Analytics Remote container...')
    data_directory = '/home/feder8/data'
    environment_variables = {
        'LOCAL_PORTAL_CLIENT_HOST': 'local-portal',
        'LOCAL_PORTAL_CLIENT_BIND': 'portal',
        'LOCAL_PORTAL_CLIENT_API': 'api',
        'R_SERVER_CLIENT_HOST': 'distributed-analytics-r-server',
        'R_SERVER_CLIENT_PORT': '8080',
        'DOCKER_RUNNER_CLIENT_HOST': 'local-portal',
        'DOCKER_RUNNER_CLIENT_CONTEXT_PATH': 'portal',
        'FEDER8_DATA_DIRECTORY': data_directory,
        'FEDER8_DATA_DOCKER_VOLUME': volume_names[0],
        'JDK_JAVA_OPTIONS': "-Dlog4j2.formatMsgNoLookups=true"
    }
    container = docker_client.containers.run(
        image=distributed_analytics_remote_image_name_tag,
        name=container_names[1],
        restart_policy={"Name": "always"},
        security_opt=['no-new-privileges'],
        remove=False,
        environment=environment_variables,
        network=network_names[0],
        volumes={
            volume_names[0]: {
                'bind': data_directory,
                'mode': 'rw'
            }
        },
        detach=True
    )

    print('Done starting Distributed Analytics Remote container')

    wait_for_healthy_container(docker_client, container, 5, 120)


@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
@click.option('-e', '--email')
@click.option('-k', '--cli-key')
@click.option('-h', '--host')
@click.option('-fsd', '--feder8-studio-directory')
@click.option('-s', '--security-method', type=click.Choice(['None', 'JDBC', 'LDAP']))
@click.option('-lu', '--ldap-url')
@click.option('-ldn', '--ldap-dn')
@click.option('-lbdn', '--ldap-base-dn')
@click.option('-lsu', '--ldap-system-username')
@click.option('-lsp', '--ldap-system-password')
def feder8_studio(therapeutic_area, email, cli_key, host, feder8_studio_directory, security_method, ldap_url, ldap_dn, ldap_base_dn, ldap_system_username, ldap_system_password):
    try:
        docker_cert_support = os.getenv('DOCKER_CERT_SUPPORT', 'false') == 'true'

        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        docker_client = get_docker_client()

        validate_correct_docker_network(docker_client)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        connect_install_container_to_network(docker_client, therapeutic_area_info)

        registry = therapeutic_area_info.registry

        configuration:ConfigurationController = get_configuration(therapeutic_area)
        if email is None:
            email = configuration.get_configuration('feder8.central.service.image-repo-username')
        if cli_key is None:
            cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')

        if host is None:
            host = configuration.get_configuration('feder8.local.host.name')

        if feder8_studio_directory is None:
            feder8_studio_directory = configuration.get_configuration('feder8.local.host.feder8-studio-directory')

        if security_method is None:
            security_method = configuration.get_configuration('feder8.local.security.security-method')

        if security_method == 'LDAP':
            if ldap_url is None:
                ldap_url = configuration.get_configuration('feder8.local.security.ldap-url')
            if ldap_dn is None:
                ldap_dn = configuration.get_configuration('feder8.local.security.ldap-dn')
            if ldap_base_dn is None:
                ldap_base_dn = configuration.get_configuration('feder8.local.security.ldap-base-dn')
            if ldap_system_username is None:
                ldap_system_username = configuration.get_configuration('feder8.local.security.ldap-system-username')
            if ldap_system_password is None:
                ldap_system_password = configuration.get_configuration('feder8.local.security.ldap-system-password')

        if docker_cert_support:
            feder8_certificate_directory = configuration.get_configuration('feder8.local.host.docker-cert-directory')
    except KeyboardInterrupt:
        sys.exit(1)

    feder8_network = get_network_name()
    network_names = [feder8_network]
    volume_names = ['feder8-data', 'shared', 'feder8-config-server']
    container_names = [therapeutic_area.lower() + '-studio', 'config-server-update-configuration']

    check_networks_and_create_if_not_exists(docker_client, network_names)
    check_volumes_and_create_if_not_exists(docker_client, volume_names)
    check_containers_and_remove_if_not_exists(docker_client, therapeutic_area_info, container_names)

    config_update = {
        'FEDER8_CONFIG_SERVER_THERAPEUTIC_AREA': therapeutic_area_info.name,
        'FEDER8_LOCAL_HOST_NAME': host,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO': registry.registry_url,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-USERNAME': email,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-KEY': cli_key,
        'FEDER8_LOCAL_HOST_FEDER8-STUDIO-DIRECTORY': feder8_studio_directory
    }
    if security_method == 'None':
        config_update['FEDER8_LOCAL_SECURITY_SECURITY-METHOD'] = 'None'
    else:
        if security_method == 'LDAP':
            config_update['FEDER8_LOCAL_SECURITY_SECURITY-METHOD'] = 'LDAP'
            config_update['FEDER8_LOCAL_SECURITY_LDAP-URL'] = ldap_url
            config_update['FEDER8_LOCAL_SECURITY_LDAP-DN'] = ldap_dn
            config_update['FEDER8_LOCAL_SECURITY_LDAP-BASE-DN'] = ldap_base_dn
            config_update['FEDER8_LOCAL_SECURITY_LDAP-SYSTEM-USERNAME'] = ldap_system_username
            config_update['FEDER8_LOCAL_SECURITY_LDAP-SYSTEM-PASSWORD'] = ldap_system_password
        else:
            config_update['FEDER8_LOCAL_SECURITY_SECURITY-METHOD'] = 'JDBC'

    update_config_on_config_server(docker_client=docker_client,
                                   email=email, cli_key=cli_key,
                                   therapeutic_area_info=therapeutic_area_info,
                                   config_update=config_update)

    feder8_studio_image_name_tag = get_feder8_studio_image_name_tag(therapeutic_area_info)

    pull_image(docker_client, registry, feder8_studio_image_name_tag, email, cli_key)

    print('Starting Feder8 Studio container...')

    environment_variables = {
        'TAG': feder8_studio_image_name_tag,
        'APPLICATION_LOGS_TO_STDOUT': 'false',
        'SITE_NAME': therapeutic_area_info.name + 'studio',
        'CONTENT_PATH': feder8_studio_directory,
        'USERID': '54321',
        'DOMAIN_NAME': host,
        'SESSION_TIMEOUT': 43200,
        'CONTAINER_WAIT_TIME': 720000,
        'HONEUR_DISTRIBUTED_ANALYTICS_DATA_FOLDER': volume_names[0],
        'HONEUR_THERAPEUTIC_AREA': therapeutic_area_info.name,
        'HONEUR_THERAPEUTIC_AREA_URL': therapeutic_area_info.registry.registry_url,
        'HONEUR_THERAPEUTIC_AREA_UPPERCASE': therapeutic_area_info.name.upper(),
        'AUTHENTICATION_METHOD': security_method.lower(),
        'JDK_JAVA_OPTIONS': "-Dlog4j2.formatMsgNoLookups=true"
    }
    if security_method == 'LDAP':
        environment_variables['HONEUR_STUDIO_LDAP_URL'] = '/'.join([ldap_url,ldap_base_dn])
        environment_variables['HONEUR_STUDIO_LDAP_DN'] = 'uid=\{0\}'
        environment_variables['HONEUR_STUDIO_LDAP_MANAGER_DN'] = ldap_system_username
        environment_variables['HONEUR_STUDIO_LDAP_MANAGER_PASSWORD'] = ldap_system_password
    elif security_method == 'JDBC':
        environment_variables['DATASOURCE_DRIVER_CLASS_NAME'] = 'org.postgresql.Driver'
        environment_variables['DATASOURCE_URL'] = 'jdbc:postgresql://postgres:5432/OHDSI?currentSchema=webapi'
        environment_variables['WEBAPI_ADMIN_USERNAME'] = 'ohdsi_admin_user'
    if docker_cert_support:
        environment_variables['PROXY_DOCKER_URL'] = 'https://172.17.0.1:2376'
        environment_variables['PROXY_DOCKER_CERT_PATH'] = '/home/certs'

    feder8_studio_volumes = {
        volume_names[1]: {
            'bind': '/var/lib/shared',
            'mode': 'ro'
        },
        feder8_studio_directory: {
            'bind': '/opt/data',
            'mode': 'ro'
        }
    }
    if docker_cert_support:
        feder8_studio_volumes[feder8_certificate_directory] = {
            'bind': '/home/certs',
            'mode': 'rw'
        }
    else:
        feder8_studio_volumes['/var/run/docker.sock'] = {
            'bind': '/var/run/docker.sock',
            'mode': 'rw'
        }

    create_or_update_host_folder_with_correct_ownership(feder8_studio_directory, 54321, 54321)

    container = docker_client.containers.run(
        image=feder8_studio_image_name_tag,
        name=container_names[0],
        restart_policy={"Name": "always"},
        security_opt=['no-new-privileges'],
        remove=False,
        environment=environment_variables,
        network=network_names[0],
        volumes=feder8_studio_volumes,
        detach=True
    )

    print('Done starting Feder8 Studio container')

    wait_for_healthy_container(docker_client, container, 5, 120)


@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
@click.option('-e', '--email')
@click.option('-k', '--cli-key')
@click.option('-fsd', '--feder8-studio-directory')
def radiant(therapeutic_area, email, cli_key, feder8_studio_directory):
    if therapeutic_area is None:
        therapeutic_area = questionary.select("Name of Therapeutic Area?",
                                              choices=Globals.therapeutic_areas.keys()).unsafe_ask()
    therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]
    registry = therapeutic_area_info.registry
    radiant_installer_image_name_tag = get_radiant_installer_image_name_tag(therapeutic_area_info)

    docker_client = get_docker_client()
    connect_install_container_to_network(docker_client, therapeutic_area_info)

    configuration: ConfigurationController = get_configuration(therapeutic_area)

    if email is None:
        email = configuration.get_configuration('feder8.central.service.image-repo-username')
    if cli_key is None:
        cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')
    if feder8_studio_directory is None:
        feder8_studio_directory = configuration.get_configuration('feder8.local.host.feder8-studio-directory')
    if feder8_studio_directory is None:
        logging.warning("Feder8 Studio installation folder not found! Unable to install radiant.")
        return

    pull_image(docker_client, registry, radiant_installer_image_name_tag, email, cli_key)

    environment_variables = {
        'THERAPEUTIC_AREA': therapeutic_area_info.name
    }

    volumes = {
        feder8_studio_directory: {
            'bind': '/opt/data',
            'mode': 'rw'
        }
    }

    container = docker_client.containers.run(
        image=radiant_installer_image_name_tag,
        name="radiant-installer",
        remove=True,
        environment=environment_variables,
        volumes=volumes,
        detach=True
    )

    for l in container.logs(stream=True):
        print(l.decode('UTF-8'), end='')


@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
@click.option('-e', '--email')
@click.option('-k', '--cli-key')
@click.option('-h', '--host')
@click.option('-es', '--enable-ssl')
@click.option('-cd', '--certificate-directory')
def nginx(therapeutic_area, email, cli_key, host, enable_ssl, certificate_directory):
    try:
        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        docker_client = get_docker_client()

        validate_correct_docker_network(docker_client)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        connect_install_container_to_network(docker_client, therapeutic_area_info)

        registry = therapeutic_area_info.registry

        configuration:ConfigurationController = get_configuration(therapeutic_area)
        if email is None:
            email = configuration.get_configuration('feder8.central.service.image-repo-username')
        if cli_key is None:
            cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')
        if host is None:
            host = configuration.get_configuration('feder8.local.host.name')
        if enable_ssl is None:
            enable_ssl = questionary.confirm('Do you want to enable HTTPS? Before you can enable HTTPS support, you should have a folder containing a public key certificate file named "feder8.crt" and a private key file named "feder8.key".').unsafe_ask()
        if enable_ssl:
            if certificate_directory is None:
                certificate_directory = configuration.get_configuration('feder8.local.host.ssl-cert-directory')
    except KeyboardInterrupt:
        sys.exit(1)

    feder8_network = get_network_name()
    network_names = [feder8_network]
    volume_names = ['feder8-config-server']
    container_names = ['nginx', 'config-server-update-configuration']

    check_networks_and_create_if_not_exists(docker_client, network_names)
    check_volumes_and_create_if_not_exists(docker_client, volume_names)
    check_containers_and_remove_if_not_exists(docker_client, therapeutic_area_info, container_names)

    config_update = {
        'FEDER8_CONFIG_SERVER_THERAPEUTIC_AREA': therapeutic_area_info.name,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO': registry.registry_url,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-USERNAME': email,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-KEY': cli_key,
        'FEDER8_LOCAL_HOST_NAME': host,
        'FEDER8_LOCAL_HOST_SSL-CERT-DIRECTORY': certificate_directory
    }

    update_config_on_config_server(docker_client=docker_client,
                                   email=email, cli_key=cli_key,
                                   therapeutic_area_info=therapeutic_area_info,
                                   config_update=config_update)

    nginx_image_name_tag = get_nginx_image_name_tag(therapeutic_area_info)

    pull_image(docker_client, registry, nginx_image_name_tag, email, cli_key)

    print('Starting Nginx container...')
    environment_variables = {
        'HONEUR_THERAPEUTIC_AREA': therapeutic_area_info.name,
        'FEDER8_HOSTNAME': host
    }
    ports = {
        '8080/tcp': 80
    }
    volumes = {}

    if enable_ssl:
        environment_variables['FEDER8_SSL_ENABLED']='true'
        ports['8443/tcp'] = 443
        volumes[certificate_directory] = {
            'bind': '/etc/nginx/certs',
            'mode': 'ro'
        }

    container = docker_client.containers.run(
        image=nginx_image_name_tag,
        name=container_names[0],
        restart_policy={"Name": "always"},
        security_opt=['no-new-privileges'],
        ports=ports,
        remove=False,
        environment=environment_variables,
        network=network_names[0],
        volumes=volumes,
        detach=True
    )

    print('Done starting Nginx container')

    wait_for_healthy_container(docker_client, container, 5, 120)


@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
def clean(therapeutic_area):
    try:
        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        docker_client = get_docker_client()

        validate_correct_docker_network(docker_client)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        connect_install_container_to_network(docker_client, therapeutic_area_info)

        confirm_continue = questionary.confirm("This script is about to delete everything installed related to " + therapeutic_area + ". Are you sure to continue?").unsafe_ask()

        if not confirm_continue:
            sys.exit(1)
    except KeyboardInterrupt:
        sys.exit(1)

    ta_network_name = get_network_name()
    try:
        ta_network = docker_client.networks.get(ta_network_name)
    except docker.errors.NotFound:
        log.warning(f"Network {ta_network_name} not found.")
        return

    all_containers = docker_client.containers.list(all=True)
    for container in all_containers:
        networks_of_container = list(container.attrs['NetworkSettings']['Networks'].keys())
        try:
            networks_of_container.remove('bridge')
        except ValueError:
            pass
        if len(networks_of_container) == 0 or networks_of_container[0] != ta_network_name:
            continue
        elif container.attrs['Name'] == '/feder8-installer':
            continue
        elif container.attrs['Name'] == '/config-server':
            continue
        else:
            print('Stopping and removing ' + container.attrs['Name'])
            try:
                container.stop()
            except:
                logging.info(f"Container {container.attrs['Name']} could not be stopped")
            try:
                container.remove(v=True)
            except docker.errors.NotFound:
                logging.info(f"Container {container.attrs['Name']} not found")
    all_containers = docker_client.containers.list(all=True)
    for container in all_containers:
        networks_of_container = list(container.attrs['NetworkSettings']['Networks'].keys())
        try:
            networks_of_container.remove('bridge')
        except ValueError:
            pass
        if len(networks_of_container) == 0 or networks_of_container[0] != ta_network_name:
            continue
        elif container.attrs['Name'] == '/config-server':
            if len(networks_of_container) == 1:
                print('Stopping and removing ' + container.attrs['Name'])
                container.stop()
                try:
                    container.remove(v=True)
                except docker.errors.NotFound:
                    pass
                docker_client.volumes.get("feder8-config-server").remove()
            else:
                print('disconnecting config-server from ' + ta_network_name)
                ta_network.disconnect(container)

    cleanup_volumes(docker_client, therapeutic_area_info.name)
    cleanup_images(docker_client, therapeutic_area_info)


def cleanup_volumes(docker_client:DockerClient, therapeutic_area_name):
    try:
        docker_client.volumes.get("shared").remove()
    except docker.errors.NotFound:
        pass
    try:
        docker_client.volumes.get("pgdata").remove()
    except docker.errors.NotFound:
        pass
    try:
        docker_client.volumes.get("cronicle_data").remove()
    except docker.errors.NotFound:
        pass
    try:
        docker_client.volumes.get(therapeutic_area_name + "studio_pwsh_modules").remove()
    except docker.errors.NotFound:
        pass
    try:
        docker_client.volumes.get(therapeutic_area_name + "studio_py_environment").remove()
    except docker.errors.NotFound:
        pass
    try:
        docker_client.volumes.get(therapeutic_area_name + "studio_r_libraries").remove()
    except docker.errors.NotFound:
        pass
    try:
        docker_client.volumes.get("pwsh_modules").remove()
    except docker.errors.NotFound:
        pass


def cleanup_images(docker_client: DockerClient, therapeutic_area_info, constraint: str = None):
    images = docker_client.images.list()
    images_to_keep = get_all_feder8_local_image_name_tags(therapeutic_area_info)
    for image in images:
        for image_tag in image.tags:
            if not therapeutic_area_info.name + "/" in image_tag: continue
            if constraint and not constraint in image_tag: continue
            if image_tag in images_to_keep: continue
            print(f"Removing image {image_tag}")
            remove_image(docker_client, image_tag)


def remove_image(docker_client:DockerClient, image_name_tag):
    try:
        docker_client.images.remove(image_name_tag)
    except:
        log.warning(f"Image {image_name_tag} could not be removed")


@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
@click.option('-e', '--email')
@click.option('-k', '--cli-key')
def backup(therapeutic_area, email, cli_key):
    try:
        is_windows = os.getenv('IS_WINDOWS', 'false') == 'true'
        directory_separator = '/'
        if is_windows:
            directory_separator = '\\'

        backup_folder = os.getenv('CURRENT_DIRECTORY', '') + directory_separator + 'backup'

        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?",
                                                  choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        docker_client = get_docker_client()

        validate_correct_docker_network(docker_client)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        connect_install_container_to_network(docker_client, therapeutic_area_info)

        if email is None:
            email, cli_key = get_image_repo_credentials(therapeutic_area, email, cli_key)

        backup_database_and_container_files(docker_client=docker_client, email=email, cli_key=cli_key,
                                            therapeutic_area_info=therapeutic_area_info,
                                            backup_folder=backup_folder)

    except KeyboardInterrupt:
        sys.exit(1)


def backup_database_and_container_files(docker_client: DockerClient, email, cli_key,
                                        therapeutic_area_info: TherapeuticArea,
                                        backup_folder: str):
    try:
        print("Creating backup of running containers. This could take a while...")

        registry = therapeutic_area_info.registry
        pull_image(docker_client, registry, get_local_backup_image_name_tag(therapeutic_area_info), email, cli_key)

        environment_variables = {
            'THERAPEUTIC_AREA': therapeutic_area_info.name,
            'BACKUP_FOLDER': backup_folder
        }

        volumes = {
            backup_folder: {
                'bind': '/opt/backup',
                'mode': 'rw'
            }
        }
        volumes = add_docker_sock_volume_mapping(volumes)

        feder8_network = get_network_name()

        container = docker_client.containers.run(image=get_local_backup_image_name_tag(therapeutic_area_info),
                                                 remove=False,
                                                 name='feder8-local-backup',
                                                 network=feder8_network,
                                                 environment=environment_variables,
                                                 volumes=volumes,
                                                 detach=True)
        for l in container.logs(stream=True):
            print(l.decode('UTF-8'), end='')

        container = docker_client.containers.get(container.attrs['Name'])
        container.stop()
        container.remove(v=True)

        if container.attrs['State']['ExitCode'] != 0:
            print('Something went wrong while taking a backup. Exiting the installation script. '
                  'If you continue to experience this error, please contact the Feder8 team.')
            sys.exit(1)
    except Exception as e:
        print(e)
        sys.exit(1)


@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
@click.option('-e', '--email')
@click.option('-k', '--cli-key')
def update_custom_concepts(therapeutic_area, email, cli_key):
    try:
        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()
        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]
        docker_client = get_docker_client()
        validate_correct_docker_network(docker_client)
        connect_install_container_to_network(docker_client, therapeutic_area_info)
        email, cli_key = get_image_repo_credentials(therapeutic_area, email, cli_key)
    except KeyboardInterrupt:
        sys.exit(1)
    pipeline = CustomConceptsUpdatePipeline(
        docker_client=get_docker_client_facade(therapeutic_area_info, email, cli_key),
        db_connection_details=get_database_connection_details(therapeutic_area))
    pipeline.execute()


@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
@click.option('-e', '--email')
@click.option('-k', '--cli-key')
def upgrade_database(therapeutic_area, email, cli_key):
    try:
        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        docker_client = get_docker_client()

        validate_correct_docker_network(docker_client)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        connect_install_container_to_network(docker_client, therapeutic_area_info)

        registry = therapeutic_area_info.registry

        configuration:ConfigurationController = get_configuration(therapeutic_area)
        if email is None:
            email = configuration.get_configuration('feder8.central.service.image-repo-username')
        if cli_key is None:
            cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')
    except KeyboardInterrupt:
        sys.exit(1)

    feder8_network = get_network_name()
    network_names = [feder8_network]
    container_names = ['pipeline-vocabulary-update']

    networks = check_networks_and_create_if_not_exists(docker_client, network_names)
    check_containers_and_remove_if_not_exists(docker_client, therapeutic_area_info, container_names)

    vocab_upgrade_image_name_tag = get_vocabulary_update_image_name_tag(therapeutic_area_info)

    print('Starting vocabulary upgrade... This could take a while.')
    pull_image(docker_client, registry, vocab_upgrade_image_name_tag, email, cli_key)

    environment_variables = {
        'DB_HOST': 'postgres',
        'THERAPEUTIC_AREA': therapeutic_area_info.name,
        'THERAPEUTIC_AREA_URL': registry.registry_url,
        'DOCKER_USERNAME': email,
        'DOCKER_PASSWORD': cli_key
    }

    volumes= {
            'shared': {
                'bind': '/var/lib/shared',
                'mode': 'ro'
            }
        }

    volumes = add_docker_sock_volume_mapping(volumes)

    container = docker_client.containers.run(image=vocab_upgrade_image_name_tag,
                                             name=container_names[0],
                                             remove=False,
                                             environment=environment_variables,
                                             network=network_names[0],
                                             volumes=volumes,
                                             detach=True)
    for l in container.logs(stream=True):
        print(l.decode('UTF-8'), end='')
    container.stop()
    container.remove(v=True)
    print('Done upgrading vocabulary')

    print('Update vocabulary and custom concepts... This could take a while.')

    alpine_image_tag = get_alpine_image_name_tag()

    container = docker_client.containers.run(image=alpine_image_tag,
                                            remove=False,
                                            name='shared-volume-permissions',
                                            volumes={
                                                'shared': {
                                                    'bind': '/var/lib/shared',
                                                    'mode': 'rw'
                                                }
                                            },
                                            command='ash -c "chown 999:999 /var/lib/shared/honeur.env"',
                                            detach=True)
    for l in container.logs(stream=True):
        print(l.decode('UTF-8'), end='')
    container.stop()
    container.remove(v=True)

    print('Make sure file permissions are correct...')
    container = docker_client.containers.run(image=alpine_image_tag,
                                            remove=False,
                                            name='shared-volume-permissions',
                                            volumes={
                                                'shared': {
                                                    'bind': '/var/lib/shared',
                                                    'mode': 'rw'
                                                }
                                            },
                                            command='ash -c "chown 999:999 /var/lib/shared/honeur.env"',
                                            detach=True)
    for l in container.logs(stream=True):
        print(l.decode('UTF-8'), end='')
    container.stop()
    container.remove(v=True)

    new_pgdata_volume = docker_client.volumes.create("new-pgdata")
    postgres_container = docker_client.containers.get("postgres")
    postgres_container.stop()
    postgres_container.remove(v=True)

    postgres_13_image_tag = get_postgres_13_image_name_tag()

    container = docker_client.containers.run(image=postgres_13_image_tag,
                                            remove=False,
                                            name='postgres',
                                            environment={
                                                'POSTGRES_PASSWORD': 'postgres'
                                            },
                                            volumes={
                                                'new-pgdata': {
                                                    'bind': '/var/lib/postgresql/data',
                                                    'mode': 'rw'
                                                }
                                            },
                                            detach=True)

    time.sleep(20)

    container.stop()
    container.remove(v=True)

    tianon_postgres_upgrade_9_6_to_13_image_name_tag = get_tianon_postgres_upgrade_9_6_to_13_image_name_tag()

    container = docker_client.containers.run(image=tianon_postgres_upgrade_9_6_to_13_image_name_tag,
                                            remove=False,
                                            name='postgres-data-upgrade',
                                            volumes={
                                                'pgdata': {
                                                    'bind': '/var/lib/postgresql/9.6/data',
                                                    'mode': 'rw'
                                                },
                                                'new-pgdata': {
                                                    'bind': '/var/lib/postgresql/13/data',
                                                    'mode': 'rw'
                                                }
                                            },
                                            detach=True)
    for l in container.logs(stream=True):
            print(l.decode('UTF-8'), end='')
    container.stop()
    container.remove(v=True)


    pgdata_volume = docker_client.volumes.get("pgdata")
    pgdata_volume.remove()

    docker_client.volumes.create("pgdata")

    container = docker_client.containers.run(image=alpine_image_tag,
                                            remove=False,
                                            name='postgres-data-upgrade',
                                            volumes={
                                                'new-pgdata': {
                                                    'bind': '/from',
                                                    'mode': 'rw'
                                                },
                                                'pgdata': {
                                                    'bind': '/to',
                                                    'mode': 'rw'
                                                }
                                            },
                                            command='ash -c "cd /from ; cp -av . /to"',
                                            detach=True)
    for l in container.logs(stream=True):
            print(l.decode('UTF-8'), end='')

    container.stop()
    container.remove(v=True)

    new_pgdata_volume.remove()


@init.command()
def is_pgdata_corrupt():
    docker_client = get_docker_client()

    validate_correct_docker_network(docker_client)

    try:
        docker_client.volumes.get("pgdata")
    except docker.errors.NotFound:
        print('Database volume not found... No sanity checks to be done.')
        return False

    print('Postgres pgdata volume found. Preparing sanity check on database...')

    try:
        postgres_container = docker_client.containers.get("postgres")
        postgres_running = postgres_container.attrs['State']['Status'] == 'running'
        postgres_container.stop()
    except docker.errors.NotFound:
        postgres_running = False
        pass

    alpine_image_tag = get_alpine_image_name_tag()

    pgdata_postgres_version = docker_client.containers.run(image=alpine_image_tag,
                                                            remove=True,
                                                            name='database',
                                                            volumes={
                                                                'pgdata': {
                                                                    'bind': '/opt/data',
                                                                    'mode': 'ro'
                                                                }
                                                            },
                                                            command='ash -c "cd /opt/data; cat /opt/data/PG_VERSION || echo 0"').rstrip().decode('UTF-8')

    postgres_9_6_image_name_tag = get_postgres_9_6_image_name_tag()
    postgres_13_image_name_tag = get_postgres_13_image_name_tag()

    if pgdata_postgres_version.startswith('9.6'):
        container = docker_client.containers.run(image=postgres_9_6_image_name_tag,
                                                remove=False,
                                                name='postgres-sanity-check',
                                                volumes={
                                                    'pgdata': {
                                                        'bind': '/var/lib/postgresql/data',
                                                        'mode': 'rw'
                                                    }
                                                },
                                                detach=True)
        time.sleep(20)

        container.reload()

        postgres_sanity_check_running = container.attrs['State']['Running'] == True
        container.stop()
        container.remove(v=True)

        if not postgres_sanity_check_running:
            print('Postgres sanity check complete... pgdata volume is corrupt.')
            return True

    elif pgdata_postgres_version.startswith('13'):
        container = docker_client.containers.run(image=postgres_13_image_name_tag,
                                                remove=False,
                                                name='postgres-sanity-check',
                                                volumes={
                                                    'pgdata': {
                                                        'bind': '/var/lib/postgresql/data',
                                                        'mode': 'rw'
                                                    }
                                                },
                                                detach=True)
        time.sleep(20)

        container.reload()

        postgres_sanity_check_running = container.attrs['State']['Running'] == True
        container.stop()
        container.remove(v=True)

        if not postgres_sanity_check_running:
            print('Postgres sanity check complete... pgdata volume is corrupt.')
            return True
    else:
        print('Could not determine version of postgres volume')
        print('Postgres sanity check complete... pgdata volume is corrupt.')
        return True

    print('Postgres sanity check complete... pgdata volume is ok.')
    try:
        postgres_container = docker_client.containers.get("postgres")
        if postgres_running:
            postgres_container.start()
    except docker.errors.NotFound:
        pass
    return False


def remove_postgres_and_pgdata_volume():
    docker_client = get_docker_client()

    try:
        postgres_container = docker_client.containers.get("postgres")
        postgres_container.stop()
        postgres_container.remove(v=True)
        print('Stopping and removing postgres container because pgdata volume is connected to this container.')
    except docker.errors.NotFound:
        pass

    try:
        docker_client.volumes.get("pgdata").remove()
        print('pgdata removed.')
    except docker.errors.NotFound:
        pass


@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
@click.option('-e', '--email')
@click.option('-k', '--cli-key')
def fix_default_privileges(therapeutic_area, email, cli_key):
    try:
        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        docker_client = get_docker_client()

        validate_correct_docker_network(docker_client)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        connect_install_container_to_network(docker_client, therapeutic_area_info)

        registry = therapeutic_area_info.registry

        configuration:ConfigurationController = get_configuration(therapeutic_area)
        if email is None:
            email = configuration.get_configuration('feder8.central.service.image-repo-username')
        if cli_key is None:
            cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')
    except KeyboardInterrupt:
        sys.exit(1)

    fix_default_privileges_image_tag = get_fix_default_privileges_image_name_tag(therapeutic_area_info)

    pull_image(docker_client,registry, fix_default_privileges_image_tag, email, cli_key)

    print('Starting fix-default-privileges container...')

    socket_gid = os.stat("/var/run/docker.sock").st_gid
    volumes = {}
    volumes = add_docker_sock_volume_mapping(volumes)

    container = docker_client.containers.run(
        image = fix_default_privileges_image_tag,
        remove = False,
        name = 'postgres-fix-default-privileges',
        volumes = volumes,
        environment={
            'FEDER8_THERAPEUTIC_AREA': therapeutic_area_info.name
        },
        group_add=[socket_gid, 0],
        detach = True)

    for l in container.logs(stream=True):
        print(l.decode('UTF-8'), end='')

    container.stop()
    container.remove(v=True)

    print('Done fix-default-privileges container')


@init.command()
def update_feder8_network():
    docker_client = get_docker_client()
    network_name = get_network_name()

    feder8_network = check_networks_and_create_if_not_exists(docker_client, [network_name])[0]

    for therapeutic_area_key in Globals.therapeutic_areas.keys():
        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area_key]
        if therapeutic_area_info.name != 'feder8':
            try:
                therapeutic_area_network = docker_client.networks.get(therapeutic_area_info.name + '-net')
                attached_containers = therapeutic_area_network.containers
                for container in attached_containers:
                    try:
                        feder8_network.connect(container)
                    except docker.errors.APIError as e:
                        if "already exists" in str(e):
                            pass
                        else:
                            raise e
                    therapeutic_area_network.disconnect(container)
                therapeutic_area_network.remove()
            except docker.errors.NotFound:
                pass


@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
@click.option('-e', '--email')
@click.option('-k', '--cli-key')
@click.option('-up', '--user-password')
@click.option('-ap', '--admin-password')
@click.option('-h', '--host')
@click.option('-s', '--security-method', type=click.Choice(['None', 'JDBC', 'LDAP']))
@click.option('-lu', '--ldap-url')
@click.option('-ldn', '--ldap-dn')
@click.option('-lbdn', '--ldap-base-dn')
@click.option('-lsu', '--ldap-system-username')
@click.option('-lsp', '--ldap-system-password')
@click.option('-ld', '--log-directory')
@click.option('-nd', '--notebook-directory')
@click.option('-fsd', '--feder8-studio-directory')
@click.option('-u', '--username')
@click.option('-p', '--password')
@click.option('-o', '--organization')
@click.option('-edr', '--enable-docker-runner')
@click.option('-edoh', '--expose-database-on-host')
@click.option('-es', '--enable-ssl')
@click.option('-cd', '--certificate-directory')
@click.pass_context
def full(ctx, therapeutic_area, email, cli_key, user_password, admin_password, host, security_method, ldap_url, ldap_dn, ldap_base_dn, ldap_system_username, ldap_system_password, log_directory, notebook_directory, feder8_studio_directory, username, password, organization, enable_docker_runner, expose_database_on_host, enable_ssl, certificate_directory):
    try:
        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        docker_client = get_docker_client()

        ctx.invoke(update_feder8_network)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        connect_install_container_to_network(docker_client, therapeutic_area_info)

        configuration:ConfigurationController = get_configuration(therapeutic_area)
        if email is None:
            email = configuration.get_configuration('feder8.central.service.image-repo-username')
        if cli_key is None:
            cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')

        try:
            docker_client.volumes.get("pgdata")
            pgdata_corrupt = ctx.invoke(is_pgdata_corrupt)
            if pgdata_corrupt:
                remove_pgdata = questionary.confirm("pgdata volume is corrupt. This is probably a result of a previous failed installation. Would you like to remove the corrupt pgdata volume?").unsafe_ask()
                if remove_pgdata:
                    remove_postgres_and_pgdata_volume()
            clean_install = questionary.confirm("A previous installation was found on your system. Would you like to remove the previous installation?").unsafe_ask()
            if clean_install:
                if not pgdata_corrupt:
                    backup_pgdata = questionary.confirm("Would you like to create a backup file of your database first?").unsafe_ask()
                    if backup_pgdata:
                        ctx.invoke(backup, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key)
                ctx.invoke(clean, therapeutic_area=therapeutic_area)
            elif not clean_install and not pgdata_corrupt:
                postgres_container = docker_client.containers.get("postgres")
                postgres_version = postgres_container.attrs['Config']['Image'].split(':')[1]
                if '9.6' in postgres_version:
                    backup_pgdata = questionary.confirm("The new installation will provide an upgraded database. Would you like to create a backup file of your database before upgrading?").unsafe_ask()
                    if backup_pgdata:
                        ctx.invoke(backup, therapeutic_area=therapeutic_area)
                    ctx.invoke(upgrade_database, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key)
            else:
                print('postgres database volume pgdata is corrupt so the installation cannot continue. Please remove the previous installation using the installation script or manually delete postgres container and pgdata volume.')
                sys.exit(1)
        except docker.errors.NotFound:
            pass
    except KeyboardInterrupt:
        sys.exit(1)

    ctx.invoke(config_server, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key)

    try:
        if user_password is None:
            user_password = configuration.get_configuration('feder8.local.datasource.password')
        if admin_password is None:
            admin_password = configuration.get_configuration('feder8.local.datasource.admin-password')
        if host is None:
            host = configuration.get_configuration('feder8.local.host.name')

        if security_method is None:
            security_method = configuration.get_configuration('feder8.local.security.security-method')

        if security_method == 'LDAP':
            if ldap_url is None:
                ldap_url = configuration.get_configuration('feder8.local.security.ldap-url')
            if ldap_dn is None:
                ldap_dn = configuration.get_configuration('feder8.local.security.ldap-dn')
            if ldap_base_dn is None:
                ldap_base_dn = configuration.get_configuration('feder8.local.security.ldap-base-dn')
            if ldap_system_username is None:
                ldap_system_username = configuration.get_configuration('feder8.local.security.ldap-system-username')
            if ldap_system_password is None:
                ldap_system_password = configuration.get_configuration('feder8.local.security.ldap-system-password')
        if log_directory is None:
            log_directory = configuration.get_configuration('feder8.local.host.zeppelin-log-directory')

        if notebook_directory is None:
            notebook_directory = configuration.get_configuration('feder8.local.host.zeppelin-notebook-directory')

        install_feder8_studio = questionary.confirm("Do you want to install Feder8 Studio?").unsafe_ask()

        if install_feder8_studio:
            if feder8_studio_directory is None:
                feder8_studio_directory = configuration.get_configuration('feder8.local.host.feder8-studio-directory')
            install_radiant = questionary.confirm("Do you want to install the Radiant app in Feder8 Studio?").unsafe_ask()

        install_distributed_analytics = questionary.confirm("Do you want to install distributed analytics?").unsafe_ask()

        if install_distributed_analytics:
            if organization is None:
                organization = questionary.select("Name of organization?", choices=therapeutic_area_info.organizations).unsafe_ask()
        if username is None:
            username = configuration.get_configuration('feder8.local.security.user-mgmt-username')
        if password is None:
            password = configuration.get_configuration('feder8.local.security.user-mgmt-password')
        if enable_docker_runner is None:
            enable_docker_runner = questionary.confirm("Do you want to enable support for Docker based analysis scripts?").unsafe_ask()
        if expose_database_on_host is None:
            expose_database_on_host = questionary.confirm("Do you want to expose the postgres database on your host through port 5444?").unsafe_ask()
        if enable_ssl is None:
            enable_ssl = questionary.confirm('Do you want to enable HTTPS? Before you can enable HTTPS support, you should have a folder containing a public key certificate file named "feder8.crt" and a private key file named "feder8.key".').unsafe_ask()
        if enable_ssl:
            if certificate_directory is None:
                certificate_directory = configuration.get_configuration('feder8.local.host.ssl-cert-directory')
    except KeyboardInterrupt:
        sys.exit(1)

    ctx.invoke(postgres, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key, user_password=user_password, admin_password=admin_password, expose_database_on_host=expose_database_on_host)
    ctx.invoke(local_portal, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key, host=host, username=username, password=password, enable_docker_runner=enable_docker_runner)
    ctx.invoke(atlas_webapi, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key, enable_ssl=enable_ssl, certificate_directory=certificate_directory, host=host, security_method=security_method, ldap_url=ldap_url, ldap_dn=ldap_dn, ldap_base_dn=ldap_base_dn, ldap_system_username=ldap_system_username, ldap_system_password=ldap_system_password)
    ctx.invoke(zeppelin, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key, log_directory=log_directory, notebook_directory=notebook_directory, security_method=security_method, ldap_url=ldap_url, ldap_dn=ldap_dn, ldap_base_dn=ldap_base_dn, ldap_system_username=ldap_system_username, ldap_system_password=ldap_system_password)
    if security_method != 'None':
        ctx.invoke(user_management, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key, username=username, password=password)
    if install_distributed_analytics:
        ctx.invoke(distributed_analytics, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key, organization=organization)
    if install_feder8_studio:
        ctx.invoke(feder8_studio, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key, host=host, feder8_studio_directory=feder8_studio_directory, security_method=security_method, ldap_url=ldap_url, ldap_dn=ldap_dn, ldap_base_dn=ldap_base_dn, ldap_system_username=ldap_system_username, ldap_system_password=ldap_system_password)
    if install_radiant:
        ctx.invoke(radiant, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key, feder8_studio_directory=feder8_studio_directory)
    ctx.invoke(task_manager, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key, feder8_studio_directory=feder8_studio_directory, security_method=security_method, admin_username=username, admin_password=password, rstudio_upload_dir=None, vscode_upload_dir=None)
    ctx.invoke(nginx, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key, enable_ssl=enable_ssl, certificate_directory=certificate_directory)

