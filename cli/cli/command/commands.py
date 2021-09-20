from docker.models.networks import Network
from cli.registry.registry import Registry
from cli.configuration.configuration_controller import ConfigurationController
import sys
import time
from typing import Container, List

from docker.client import DockerClient
from cli.globals import Globals
import click
import questionary
import docker
import os
import requests


def run_container(docker_client:DockerClient, image:str, remove:bool, name:str, environment, network:str, volumes, detach:bool, show_logs:bool):
    container = docker_client.containers.run(
        image, remove=remove, name=name, environment=environment, network=network, volumes=volumes, detach=detach)
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

def check_containers_and_remove_if_not_exists(docker_client:DockerClient, container_names:List[str]):
    for container_name in container_names:
        try:
            container = docker_client.containers.get(container_name)
            print(' '.join([container_name,'is running.']))
            print(' '.join(['Removing',container_name,'container...']))
            container.stop()
            container.remove(v=True)
            print(' '.join(['Done removing',container_name,'container...']))
        except:
            pass

def pull_image(docker_client:DockerClient, registry:Registry, image:str, email:str, cli_key:str):
    print(' '.join(['Pulling image', image, '...']))
    try:
        docker_client.login(username=email, password=cli_key, registry=registry.registry_url)
    except docker.errors.APIError:
        print('Failed to pull image. Are the correct email and CLI Key provided?')
        sys.exit(1)
    docker_client.images.pull(image)
    print(' '.join(['Done pulling image', image]))

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
        current_environment = os.getenv('CURRENT_DIRECTORY', '')
        is_windows = os.getenv('IS_WINDOWS', 'false') == 'true'
        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        try:
            docker_client = docker.from_env(timeout=3000)
        except docker.errors.DockerException:
            print('Error while fetching docker api... Is docker running?')
            sys.exit(1)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        try:
            ta_network = docker_client.networks.get(therapeutic_area_info.name + "-net")
        except docker.errors.NotFound:
            ta_network = docker_client.networks.create(therapeutic_area_info.name + "-net", check_duplicate=True)
        install_container = docker_client.containers.get("feder8-installer")

        try:
            ta_network.connect(install_container)
        except docker.errors.APIError:
            pass

        registry = therapeutic_area_info.registry

        configuration:ConfigurationController = ConfigurationController(therapeutic_area, current_environment, is_windows)
        if email is None:
            email = configuration.get_configuration('feder8.central.service.image-repo-username')
        if cli_key is None:
            cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')
    except KeyboardInterrupt:
        sys.exit(1)

    network_names = [therapeutic_area.lower() + '-net']
    volume_names = ['feder8-config-server']
    container_names = ['config-server', 'config-server-update-configuration']

    networks = check_networks_and_create_if_not_exists(docker_client, network_names)
    volumes = check_volumes_and_create_if_not_exists(docker_client, volume_names)
    check_containers_and_remove_if_not_exists(docker_client, container_names)

    init_config_repo = '/'.join([registry.registry_url, registry.project, 'config-server'])
    init_config_tag = 'update-configuration-2.0.0'
    init_config_image = ':'.join([init_config_repo, init_config_tag])

    pull_image(docker_client,registry, init_config_image, email, cli_key)

    print('Updating configuration in config-server...')
    run_container(
        docker_client=docker_client,
        image=init_config_image,
        remove=True,
        name=container_names[1],
        environment={
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
        },
        network=network_names[0],
        volumes={
            volume_names[0]: {
                'bind': '/home/feder8/config-repo',
                'mode': 'rw'
            }
        },
        detach=True,
        show_logs=True)

    try:
        docker_client.containers.get("local-portal")
        url = 'http://local-portal/portal/actuator/refresh'
        requests.post(url)
    except docker.errors.NotFound:
        pass

    print('Done updating configuration in config-server')

    config_server_repo = '/'.join([registry.registry_url, registry.project, 'config-server'])
    config_server_tag = '2.0.0'
    config_server_image = ':'.join([config_server_repo, config_server_tag])

    pull_image(docker_client,registry, config_server_image, email, cli_key)

    print('Starting config-server container...')
    container = docker_client.containers.run(
        image=config_server_image,
        name=container_names[0],
        restart_policy={"Name": "always"},
        security_opt=['no-new-privileges'],
        remove=False,
        environment={
            'SERVER_FORWARD_HEADERS_STRATEGY': 'framework',
            'SERVER_SERVLET_CONTEXT_PATH': '/config-server'
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
def postgres(therapeutic_area, email, cli_key, user_password, admin_password):
    try:
        current_environment = os.getenv('CURRENT_DIRECTORY', '')
        is_windows = os.getenv('IS_WINDOWS', 'false') == 'true'
        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        try:
            docker_client = docker.from_env(timeout=3000)
        except docker.errors.DockerException:
            print('Error while fetching docker api... Is docker running?')
            sys.exit(1)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        try:
            ta_network = docker_client.networks.get(therapeutic_area_info.name + "-net")
        except docker.errors.NotFound:
            ta_network = docker_client.networks.create(therapeutic_area_info.name + "-net", check_duplicate=True)
        install_container = docker_client.containers.get("feder8-installer")

        try:
            ta_network.connect(install_container)
        except docker.errors.APIError:
            pass

        registry = therapeutic_area_info.registry

        configuration:ConfigurationController = ConfigurationController(therapeutic_area, current_environment, is_windows)
        if email is None:
            email = configuration.get_configuration('feder8.central.service.image-repo-username')
        if cli_key is None:
            cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')
        if user_password is None:
            user_password = configuration.get_configuration('feder8.local.datasource.password')
        if admin_password is None:
            admin_password = configuration.get_configuration('feder8.local.datasource.admin-password')

        expose_database_on_host = questionary.confirm("Do you want to expose the postgres database on your host through port 5444?").unsafe_ask()
    except KeyboardInterrupt:
        sys.exit(1)

    network_names = [therapeutic_area.lower() + '-net']
    volume_names = ['pgdata', 'shared', 'feder8-config-server']
    container_names = ['postgres', 'config-server-update-configuration']

    networks = check_networks_and_create_if_not_exists(docker_client, network_names)
    volumes = check_volumes_and_create_if_not_exists(docker_client, volume_names)
    check_containers_and_remove_if_not_exists(docker_client, container_names)

    init_config_repo = '/'.join([registry.registry_url, registry.project, 'config-server'])
    init_config_tag = 'update-configuration-2.0.0'
    init_config_image = ':'.join([init_config_repo, init_config_tag])

    pull_image(docker_client,registry, init_config_image, email, cli_key)

    print('Updating configuration in config-server...')
    run_container(
        docker_client=docker_client,
        image=init_config_image,
        remove=True,
        name=container_names[1],
        environment={
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
        },
        network=network_names[0],
        volumes={
            volume_names[2]: {
                'bind': '/home/feder8/config-repo',
                'mode': 'rw'
            }
        },
        detach=True,
        show_logs=True)

    try:
        docker_client.containers.get("local-portal")
        url = 'http://local-portal/portal/actuator/refresh'
        requests.post(url)
    except docker.errors.NotFound:
        pass

    print('Done updating configuration in config-server')

    postgres_repo = '/'.join([registry.registry_url, registry.project, 'postgres'])
    postgres_tag = '13-omopcdm-5.3.1-webapi-2.9.0-2.0.3'
    postgres_image = ':'.join([postgres_repo, postgres_tag])

    pull_image(docker_client,registry, postgres_image, email, cli_key)

    print('Starting postgres container...')
    docker_client

    ports = {}
    if expose_database_on_host:
        ports['5432/tcp'] = 5444

    container = docker_client.containers.run(
        image=postgres_image,
        name=container_names[0],
        ports=ports,
        restart_policy={"Name": "always"},
        security_opt=['no-new-privileges'],
        remove=False,
        environment={
            'HONEUR_USER_USERNAME': therapeutic_area_info.name,
            'HONEUR_USER_PW': user_password,
            'HONEUR_ADMIN_USER_USERNAME': therapeutic_area_info.name + '_admin',
            'HONEUR_ADMIN_USER_PW': admin_password
        },
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


@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
@click.option('-e', '--email')
@click.option('-k', '--cli-key')
@click.option('-h', '--host')
def local_portal(therapeutic_area, email, cli_key, host):
    try:
        current_environment = os.getenv('CURRENT_DIRECTORY', '')
        is_windows = os.getenv('IS_WINDOWS', 'false') == 'true'
        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        try:
            docker_client = docker.from_env(timeout=3000)
        except docker.errors.DockerException:
            print('Error while fetching docker api... Is docker running?')
            sys.exit(1)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        try:
            ta_network = docker_client.networks.get(therapeutic_area_info.name + "-net")
        except docker.errors.NotFound:
            ta_network = docker_client.networks.create(therapeutic_area_info.name + "-net", check_duplicate=True)
        install_container = docker_client.containers.get("feder8-installer")

        try:
            ta_network.connect(install_container)
        except docker.errors.APIError:
            pass

        registry = therapeutic_area_info.registry

        configuration:ConfigurationController = ConfigurationController(therapeutic_area, current_environment, is_windows)
        if email is None:
            email = configuration.get_configuration('feder8.central.service.image-repo-username')
        if cli_key is None:
            cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')
        if host is None:
            host = configuration.get_configuration('feder8.local.host.name')
    except KeyboardInterrupt:
        sys.exit(1)

    network_names = [therapeutic_area.lower() + '-net']
    volume_names = ['shared', 'feder8-config-server']
    container_names = ['local-portal', 'config-server-update-configuration']

    networks = check_networks_and_create_if_not_exists(docker_client, network_names)
    volumes = check_volumes_and_create_if_not_exists(docker_client, volume_names)
    check_containers_and_remove_if_not_exists(docker_client, container_names)

    init_config_repo = '/'.join([registry.registry_url, registry.project, 'config-server'])
    init_config_tag = 'update-configuration-2.0.0'
    init_config_image = ':'.join([init_config_repo, init_config_tag])
    pull_image(docker_client,registry, init_config_image, email, cli_key)

    print('Updating configuration in config-server...')
    run_container(
        docker_client=docker_client,
        image=init_config_image,
        remove=True,
        name=container_names[1],
        environment={
            'FEDER8_CONFIG_SERVER_THERAPEUTIC_AREA': therapeutic_area_info.name,
            'FEDER8_CENTRAL_SERVICE_IMAGE-REPO': registry.registry_url,
            'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-USERNAME': email,
            'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-KEY': cli_key,
            'FEDER8_LOCAL_HOST_NAME': host
        },
        network=network_names[0],
        volumes={
            volume_names[1]: {
                'bind': '/home/feder8/config-repo',
                'mode': 'rw'
            }
        },
        detach=True,
        show_logs=True)

    try:
        docker_client.containers.get("local-portal")
        url = 'http://local-portal/portal/actuator/refresh'
        requests.post(url)
    except docker.errors.NotFound:
        pass

    print('Done updating configuration in config-server')

    local_portal_repo = '/'.join([registry.registry_url, registry.project, 'local-portal'])
    local_portal_tag = '2.0.0'
    local_portal_image = ':'.join([local_portal_repo, local_portal_tag])

    pull_image(docker_client,registry, local_portal_image, email, cli_key)

    print('Starting local-portal container...')
    socket_gid = os.stat("/var/run/docker.sock").st_gid
    container = docker_client.containers.run(
        image=local_portal_image,
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
            'SERVER_FORWARD_HEADERS_STRATEGY': 'framework',
            'SERVER_SERVLET_CONTEXT_PATH': '/portal'
        },
        network=network_names[0],
        volumes={
            volume_names[0]: {
                'bind': '/var/lib/shared',
                'mode': 'ro'
            },
            volume_names[1]: {
                'bind': '/home/feder8/config-repo',
                'mode': 'rw'
            },
            '/var/run/docker.sock': {
                'bind': '/var/run/docker.sock',
                'mode': 'rw'
            }
        },
        group_add=[socket_gid],
        detach=True
    )

    print('Done starting local-portal container')

    wait_for_healthy_container(docker_client, container, 5, 120)

@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
@click.option('-e', '--email')
@click.option('-k', '--cli-key')
@click.option('-h', '--host')
@click.option('-s', '--security-method', type=click.Choice(['None', 'JDBC', 'LDAP']))
@click.option('-lu', '--ldap-url')
@click.option('-ldn', '--ldap-dn')
@click.option('-lbdn', '--ldap-base-dn')
@click.option('-lsu', '--ldap-system-username')
@click.option('-lsp', '--ldap-system-password')
def atlas_webapi(therapeutic_area, email, cli_key, host, security_method, ldap_url, ldap_dn, ldap_base_dn, ldap_system_username, ldap_system_password):
    try:
        current_environment = os.getenv('CURRENT_DIRECTORY', '')
        is_windows = os.getenv('IS_WINDOWS', 'false') == 'true'
        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        try:
            docker_client = docker.from_env(timeout=3000)
        except docker.errors.DockerException:
            print('Error while fetching docker api... Is docker running?')
            sys.exit(1)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        try:
            ta_network = docker_client.networks.get(therapeutic_area_info.name + "-net")
        except docker.errors.NotFound:
            ta_network = docker_client.networks.create(therapeutic_area_info.name + "-net", check_duplicate=True)
        install_container = docker_client.containers.get("feder8-installer")

        try:
            ta_network.connect(install_container)
        except docker.errors.APIError:
            pass

        registry = therapeutic_area_info.registry

        configuration:ConfigurationController = ConfigurationController(therapeutic_area, current_environment, is_windows)
        if email is None:
            email = configuration.get_configuration('feder8.central.service.image-repo-username')
        if cli_key is None:
            cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')

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
    except KeyboardInterrupt:
        sys.exit(1)

    network_names = [therapeutic_area.lower() + '-net']
    volume_names = ['shared', 'feder8-config-server']
    container_names = ['webapi', 'atlas', 'config-server-update-configuration']

    networks = check_networks_and_create_if_not_exists(docker_client, network_names)
    volumes = check_volumes_and_create_if_not_exists(docker_client, volume_names)
    check_containers_and_remove_if_not_exists(docker_client, container_names)

    init_config_repo = '/'.join([registry.registry_url, registry.project, 'config-server'])
    init_config_tag = 'update-configuration-2.0.0'
    init_config_image = ':'.join([init_config_repo, init_config_tag])
    pull_image(docker_client,registry, init_config_image, email, cli_key)

    print('Updating configuration in config-server...')
    environment_variables = {
        'FEDER8_CONFIG_SERVER_THERAPEUTIC_AREA': therapeutic_area_info.name,
        'FEDER8_LOCAL_HOST_NAME': host,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO': registry.registry_url,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-USERNAME': email,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-KEY': cli_key,
    }
    if security_method == 'None':
        environment_variables['FEDER8_LOCAL_SECURITY_SECURITY-METHOD'] = 'None'
    else:
        if security_method == 'LDAP':
            environment_variables['FEDER8_LOCAL_SECURITY_SECURITY-METHOD'] = 'LDAP'
            environment_variables['FEDER8_LOCAL_SECURITY_LDAP-URL'] = ldap_url
            environment_variables['FEDER8_LOCAL_SECURITY_LDAP-DN'] = ldap_dn
            environment_variables['FEDER8_LOCAL_SECURITY_LDAP-BASE-DN'] = ldap_base_dn
            environment_variables['FEDER8_LOCAL_SECURITY_LDAP-SYSTEM-USERNAME'] = ldap_system_username
            environment_variables['FEDER8_LOCAL_SECURITY_LDAP-SYSTEM-PASSWORD'] = ldap_system_password
        else:
            environment_variables['FEDER8_LOCAL_SECURITY_SECURITY-METHOD'] = 'JDBC'

    run_container(
        docker_client=docker_client,
        image=init_config_image,
        remove=True,
        name=container_names[2],
        environment=environment_variables,
        network=network_names[0],
        volumes={
            volume_names[1]: {
                'bind': '/home/feder8/config-repo',
                'mode': 'rw'
            }
        },
        detach=True,
        show_logs=True)

    try:
        docker_client.containers.get("local-portal")
        url = 'http://local-portal/portal/actuator/refresh'
        requests.post(url)
    except docker.errors.NotFound:
        pass

    print('Done updating configuration in config-server')

    webapi_repo = '/'.join([registry.registry_url, registry.project, 'webapi'])
    webapi_tag = '2.9.0-2.0.0'
    webapi_image = ':'.join([webapi_repo, webapi_tag])

    pull_image(docker_client, registry, webapi_image, email, cli_key)

    print('Starting WebAPI container...')
    environment_variables = {
        'DB_HOST': 'postgres',
        'FEDER8_WEBAPI_CENTRAL': 'false',
        'SERVER_CONTEXT_PATH': '/webapi',
        'SERVER_USE_FORWARD_HEADERS': 'true'
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
        image=webapi_image,
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

    atlas_repo = '/'.join([registry.registry_url, registry.project, 'atlas'])
    atlas_tag = '2.9.0-2.0.0'
    atlas_image = ':'.join([atlas_repo, atlas_tag])
    pull_image(docker_client,registry, atlas_image, email, cli_key)

    print('Starting Atlas container...')
    environment_variables = {
        'FEDER8_WEBAPI_URL': 'http://' + host + '/webapi/',
        'FEDER8_ATLAS_CENTRAL': 'false',
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
        image=atlas_image,
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
        current_environment = os.getenv('CURRENT_DIRECTORY', '')
        is_windows = os.getenv('IS_WINDOWS', 'false') == 'true'
        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        try:
            docker_client = docker.from_env(timeout=3000)
        except docker.errors.DockerException:
            print('Error while fetching docker api... Is docker running?')
            sys.exit(1)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        try:
            ta_network = docker_client.networks.get(therapeutic_area_info.name + "-net")
        except docker.errors.NotFound:
            ta_network = docker_client.networks.create(therapeutic_area_info.name + "-net", check_duplicate=True)
        install_container = docker_client.containers.get("feder8-installer")

        try:
            ta_network.connect(install_container)
        except docker.errors.APIError:
            pass

        registry = therapeutic_area_info.registry

        configuration:ConfigurationController = ConfigurationController(therapeutic_area, current_environment, is_windows)
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

    network_names = [therapeutic_area.lower() + '-net']
    volume_names = ['feder8-data', 'shared', 'feder8-config-server']
    container_names = ['zeppelin', 'config-server-update-configuration']

    networks = check_networks_and_create_if_not_exists(docker_client, network_names)
    volumes = check_volumes_and_create_if_not_exists(docker_client, volume_names)
    check_containers_and_remove_if_not_exists(docker_client, container_names)

    init_config_repo = '/'.join([registry.registry_url, registry.project, 'config-server'])
    init_config_tag = 'update-configuration-2.0.0'
    init_config_image = ':'.join([init_config_repo, init_config_tag])
    pull_image(docker_client,registry, init_config_image, email, cli_key)

    print('Updating configuration in config-server...')
    environment_variables = {
        'FEDER8_CONFIG_SERVER_THERAPEUTIC_AREA': therapeutic_area_info.name,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO': registry.registry_url,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-USERNAME': email,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-KEY': cli_key,
        'FEDER8_LOCAL_HOST_ZEPPELIN-LOG-DIRECTORY': log_directory,
        'FEDER8_LOCAL_HOST_ZEPPELIN-NOTEBOOK-DIRECTORY': notebook_directory
    }
    if security_method == 'None':
        environment_variables['FEDER8_LOCAL_SECURITY_SECURITY-METHOD'] = 'None'
    else:
        if security_method == 'LDAP':
            environment_variables['FEDER8_LOCAL_SECURITY_SECURITY-METHOD'] = 'LDAP'
            environment_variables['FEDER8_LOCAL_SECURITY_LDAP-URL'] = ldap_url
            environment_variables['FEDER8_LOCAL_SECURITY_LDAP-DN'] = ldap_dn
            environment_variables['FEDER8_LOCAL_SECURITY_LDAP-BASE-DN'] = ldap_base_dn
            environment_variables['FEDER8_LOCAL_SECURITY_LDAP-SYSTEM-USERNAME'] = ldap_system_username
            environment_variables['FEDER8_LOCAL_SECURITY_LDAP-SYSTEM-PASSWORD'] = ldap_system_password
        else:
            environment_variables['FEDER8_LOCAL_SECURITY_SECURITY-METHOD'] = 'JDBC'

    run_container(
        docker_client=docker_client,
        image=init_config_image,
        remove=True,
        name=container_names[1],
        environment=environment_variables,
        network=network_names[0],
        volumes={
            volume_names[2]: {
                'bind': '/home/feder8/config-repo',
                'mode': 'rw'
            }
        },
        detach=True,
        show_logs=True)

    try:
        docker_client.containers.get("local-portal")
        url = 'http://local-portal/portal/actuator/refresh'
        requests.post(url)
    except docker.errors.NotFound:
        pass

    print('Done updating configuration in config-server')

    zeppelin_repo = '/'.join([registry.registry_url, registry.project, 'zeppelin'])
    zeppelin_tag = '0.8.2-2.0.1'
    zeppelin_image = ':'.join([zeppelin_repo, zeppelin_tag])

    pull_image(docker_client, registry, zeppelin_image, email, cli_key)

    print('Starting Zeppelin container...')
    environment_variables = {
        'ZEPPELIN_NOTEBOOK_DIR': '/notebook',
        'FEDER8_WEBAPI_CENTRAL': 'false',
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
        image=zeppelin_image,
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
        current_environment = os.getenv('CURRENT_DIRECTORY', '')
        is_windows = os.getenv('IS_WINDOWS', 'false') == 'true'
        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        try:
            docker_client = docker.from_env(timeout=3000)
        except docker.errors.DockerException:
            print('Error while fetching docker api... Is docker running?')
            sys.exit(1)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        try:
            ta_network = docker_client.networks.get(therapeutic_area_info.name + "-net")
        except docker.errors.NotFound:
            ta_network = docker_client.networks.create(therapeutic_area_info.name + "-net", check_duplicate=True)
        install_container = docker_client.containers.get("feder8-installer")

        try:
            ta_network.connect(install_container)
        except docker.errors.APIError:
            pass

        registry = therapeutic_area_info.registry

        configuration:ConfigurationController = ConfigurationController(therapeutic_area, current_environment, is_windows)

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

    network_names = [therapeutic_area.lower() + '-net']
    volume_names = ['shared', 'feder8-config-server']
    container_names = ['user-mgmt', 'config-server-update-configuration']

    networks = check_networks_and_create_if_not_exists(docker_client, network_names)
    volumes = check_volumes_and_create_if_not_exists(docker_client, volume_names)
    check_containers_and_remove_if_not_exists(docker_client, container_names)

    init_config_repo = '/'.join([registry.registry_url, registry.project, 'config-server'])
    init_config_tag = 'update-configuration-2.0.0'
    init_config_image = ':'.join([init_config_repo, init_config_tag])

    pull_image(docker_client,registry, init_config_image, email, cli_key)

    print('Updating configuration in config-server...')
    environment_variables = {
        'FEDER8_CONFIG_SERVER_THERAPEUTIC_AREA': therapeutic_area_info.name,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO': registry.registry_url,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-USERNAME': email,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-KEY': cli_key,
        'FEDER8_LOCAL_SECURITY_USER-MGMT-USERNAME': username,
        'FEDER8_LOCAL_SECURITY_USER-MGMT-PASSWORD': password
    }
    run_container(
        docker_client=docker_client,
        image=init_config_image,
        remove=True,
        name=container_names[1],
        environment=environment_variables,
        network=network_names[0],
        volumes={
            volume_names[1]: {
                'bind': '/home/feder8/config-repo',
                'mode': 'rw'
            }
        },
        detach=True,
        show_logs=True)

    try:
        docker_client.containers.get("local-portal")
        url = 'http://local-portal/portal/actuator/refresh'
        requests.post(url)
    except docker.errors.NotFound:
        pass

    print('Done updating configuration in config-server')

    user_management_repo = '/'.join([registry.registry_url, registry.project, 'user-mgmt'])
    user_management_tag = '2.0.2'
    user_management_image = ':'.join([user_management_repo, user_management_tag])

    pull_image(docker_client, registry, user_management_image, email, cli_key)

    print('Starting User Management container...')
    environment_variables = {
        'HONEUR_THERAPEUTIC_AREA_NAME': therapeutic_area_info.name,
        'HONEUR_THERAPEUTIC_AREA_LIGHT_THEME_COLOR': therapeutic_area_info.light_theme,
        'HONEUR_THERAPEUTIC_AREA_DARK_THEME_COLOR': therapeutic_area_info.dark_theme,
        'HONEUR_USERMGMT_USERNAME': username,
        'HONEUR_USERMGMT_PASSWORD': password,
        'DATASOURCE_DRIVER_CLASS_NAME': 'org.postgresql.Driver',
        'DATASOURCE_URL': 'jdbc:postgresql://postgres:5432/OHDSI?currentSchema=webapi',
        'WEBAPI_ADMIN_USERNAME': 'ohdsi_admin_user'
    }
    container = docker_client.containers.run(
        image=user_management_image,
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
@click.option('-o', '--organization')
def distributed_analytics(therapeutic_area, email, cli_key, organization):
    try:
        current_environment = os.getenv('CURRENT_DIRECTORY', '')
        is_windows = os.getenv('IS_WINDOWS', 'false') == 'true'
        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        try:
            docker_client = docker.from_env(timeout=3000)
        except docker.errors.DockerException:
            print('Error while fetching docker api... Is docker running?')
            sys.exit(1)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        try:
            ta_network = docker_client.networks.get(therapeutic_area_info.name + "-net")
        except docker.errors.NotFound:
            ta_network = docker_client.networks.create(therapeutic_area_info.name + "-net", check_duplicate=True)
        install_container = docker_client.containers.get("feder8-installer")

        try:
            ta_network.connect(install_container)
        except docker.errors.APIError:
            pass

        registry = therapeutic_area_info.registry

        configuration:ConfigurationController = ConfigurationController(therapeutic_area, current_environment, is_windows)

        if email is None:
            email = configuration.get_configuration('feder8.central.service.image-repo-username')
        if cli_key is None:
            cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')

        if organization is None:
            organization = questionary.select("Name of organization?", choices=therapeutic_area_info.organizations).unsafe_ask()

    except KeyboardInterrupt:
        sys.exit(1)

    network_names = [therapeutic_area.lower() + '-net']
    volume_names = ['feder8-data', 'feder8-config-server']
    container_names = ['distributed-analytics-r-server', 'distributed-analytics-remote', 'config-server-update-configuration']

    networks = check_networks_and_create_if_not_exists(docker_client, network_names)
    volumes = check_volumes_and_create_if_not_exists(docker_client, volume_names)
    check_containers_and_remove_if_not_exists(docker_client, container_names)

    init_config_repo = '/'.join([registry.registry_url, registry.project, 'config-server'])
    init_config_tag = 'update-configuration-2.0.0'
    init_config_image = ':'.join([init_config_repo, init_config_tag])
    pull_image(docker_client,registry, init_config_image, email, cli_key)

    print('Updating configuration in config-server...')
    environment_variables = {
        'FEDER8_CONFIG_SERVER_THERAPEUTIC_AREA': therapeutic_area_info.name,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO': registry.registry_url,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-USERNAME': email,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-KEY': cli_key
    }
    run_container(
        docker_client=docker_client,
        image=init_config_image,
        remove=True,
        name=container_names[2],
        environment=environment_variables,
        network=network_names[0],
        volumes={
            volume_names[1]: {
                'bind': '/home/feder8/config-repo',
                'mode': 'rw'
            }
        },
        detach=True,
        show_logs=True)

    try:
        docker_client.containers.get("local-portal")
        url = 'http://local-portal/portal/actuator/refresh'
        requests.post(url)
    except docker.errors.NotFound:
        pass

    print('Done updating configuration in config-server')

    distributed_analytics_r_server_repo = '/'.join([registry.registry_url, registry.project, 'distributed-analytics'])
    distributed_analytics_r_server_tag = 'r-server-2.0.4'
    distributed_analytics_r_server_image = ':'.join([distributed_analytics_r_server_repo, distributed_analytics_r_server_tag])

    pull_image(docker_client, registry, distributed_analytics_r_server_image, email, cli_key)

    print('Starting Distributed Analytics R Server container...')
    environment_variables = {}
    container = docker_client.containers.run(
        image=distributed_analytics_r_server_image,
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

    distributed_analytics_remote_repo = '/'.join([registry.registry_url, registry.project, 'distributed-analytics'])
    distributed_analytics_remote_tag = 'remote-2.0.3'
    distributed_analytics_remote_image = ':'.join([distributed_analytics_remote_repo, distributed_analytics_remote_tag])

    pull_image(docker_client, registry, distributed_analytics_remote_image, email, cli_key)

    print('Starting Distributed Analytics Remote container...')
    environment_variables = {
        'DISTRIBUTED_SERVICE_CLIENT_HOST': therapeutic_area_info.distributed_analytics_url,
        'DISTRIBUTED_SERVICE_CLIENT_BIND': '',
        'LOCAL_CONFIGURATION_CLIENT_HOST': 'local-portal',
        'LOCAL_CONFIGURATION_CLIENT_BIND': 'portal',
        'LOCAL_CONFIGURATION_CLIENT_API': 'api',
        'R_SERVER_CLIENT_HOST': 'distributed-analytics-r-server',
        'R_SERVER_CLIENT_PORT': '8080',
        'DOCKER_RUNNER_CLIENT_HOST': 'local-portal',
        'DOCKER_RUNNER_CLIENT_CONTEXT_PATH': 'portal',
        'FEDER8_ANALYTICS_ORGANIZATION': organization,
        'FEDER8_DATA_DIRECTORY': volume_names[0]
    }
    container = docker_client.containers.run(
        image=distributed_analytics_remote_image,
        name=container_names[1],
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
        current_environment = os.getenv('CURRENT_DIRECTORY', '')
        is_windows = os.getenv('IS_WINDOWS', 'false') == 'true'
        docker_cert_support = os.getenv('DOCKER_CERT_SUPPORT', 'false') == 'true'

        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        try:
            docker_client = docker.from_env(timeout=3000)
        except docker.errors.DockerException:
            print('Error while fetching docker api... Is docker running?')
            sys.exit(1)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        try:
            ta_network = docker_client.networks.get(therapeutic_area_info.name + "-net")
        except docker.errors.NotFound:
            ta_network = docker_client.networks.create(therapeutic_area_info.name + "-net", check_duplicate=True)
        install_container = docker_client.containers.get("feder8-installer")

        try:
            ta_network.connect(install_container)
        except docker.errors.APIError:
            pass

        registry = therapeutic_area_info.registry

        configuration:ConfigurationController = ConfigurationController(therapeutic_area, current_environment, is_windows)
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

    network_names = [therapeutic_area.lower() + '-net']
    volume_names = ['feder8-data', 'shared', 'feder8-config-server']
    container_names = [therapeutic_area.lower() + '-studio', 'config-server-update-configuration']

    networks = check_networks_and_create_if_not_exists(docker_client, network_names)
    volumes = check_volumes_and_create_if_not_exists(docker_client, volume_names)
    check_containers_and_remove_if_not_exists(docker_client, container_names)

    init_config_repo = '/'.join([registry.registry_url, registry.project, 'config-server'])
    init_config_tag = 'update-configuration-2.0.0'
    init_config_image = ':'.join([init_config_repo, init_config_tag])
    pull_image(docker_client,registry, init_config_image, email, cli_key)

    print('Updating configuration in config-server...')
    environment_variables = {
        'FEDER8_CONFIG_SERVER_THERAPEUTIC_AREA': therapeutic_area_info.name,
        'FEDER8_LOCAL_HOST_NAME': host,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO': registry.registry_url,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-USERNAME': email,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-KEY': cli_key,
        'FEDER8_LOCAL_HOST_FEDER8-STUDIO-DIRECTORY': feder8_studio_directory
    }
    if security_method == 'None':
        environment_variables['FEDER8_LOCAL_SECURITY_SECURITY-METHOD'] = 'None'
    else:
        if security_method == 'LDAP':
            environment_variables['FEDER8_LOCAL_SECURITY_SECURITY-METHOD'] = 'LDAP'
            environment_variables['FEDER8_LOCAL_SECURITY_LDAP-URL'] = ldap_url
            environment_variables['FEDER8_LOCAL_SECURITY_LDAP-DN'] = ldap_dn
            environment_variables['FEDER8_LOCAL_SECURITY_LDAP-BASE-DN'] = ldap_base_dn
            environment_variables['FEDER8_LOCAL_SECURITY_LDAP-SYSTEM-USERNAME'] = ldap_system_username
            environment_variables['FEDER8_LOCAL_SECURITY_LDAP-SYSTEM-PASSWORD'] = ldap_system_password
        else:
            environment_variables['FEDER8_LOCAL_SECURITY_SECURITY-METHOD'] = 'JDBC'
    run_container(
        docker_client=docker_client,
        image=init_config_image,
        remove=True,
        name=container_names[1],
        environment=environment_variables,
        network=network_names[0],
        volumes={
            volume_names[2]: {
                'bind': '/home/feder8/config-repo',
                'mode': 'rw'
            }
        },
        detach=True,
        show_logs=True)

    try:
        docker_client.containers.get("local-portal")
        url = 'http://local-portal/portal/actuator/refresh'
        requests.post(url)
    except docker.errors.NotFound:
        pass

    print('Done updating configuration in config-server')

    feder8_studio_repo = '/'.join([registry.registry_url, registry.project, 'feder8-studio'])
    feder8_studio_tag = '2.0.5'
    feder8_studio_image = ':'.join([feder8_studio_repo, feder8_studio_tag])

    pull_image(docker_client, registry, feder8_studio_image, email, cli_key)

    print('Starting Feder8 Studio container...')

    environment_variables = {
        'TAG': feder8_studio_tag,
        'APPLICATION_LOGS_TO_STDOUT': 'false',
        'SITE_NAME': therapeutic_area_info.name + 'studio',
        'CONTENT_PATH': feder8_studio_directory,
        'USERID': '54321',
        'DOMAIN_NAME': host,
        'HONEUR_DISTRIBUTED_ANALYTICS_DATA_FOLDER': volume_names[0],
        'HONEUR_THERAPEUTIC_AREA': therapeutic_area_info.name,
        'HONEUR_THERAPEUTIC_AREA_URL': therapeutic_area_info.registry.registry_url,
        'HONEUR_THERAPEUTIC_AREA_UPPERCASE': therapeutic_area_info.name.upper(),
        'AUTHENTICATION_METHOD': security_method.lower()
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
    container = docker_client.containers.run(
        image=feder8_studio_image,
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
def nginx(therapeutic_area, email, cli_key):
    try:
        current_environment = os.getenv('CURRENT_DIRECTORY', '')
        is_windows = os.getenv('IS_WINDOWS', 'false') == 'true'
        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        try:
            docker_client = docker.from_env(timeout=3000)
        except docker.errors.DockerException:
            print('Error while fetching docker api... Is docker running?')
            sys.exit(1)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        try:
            ta_network = docker_client.networks.get(therapeutic_area_info.name + "-net")
        except docker.errors.NotFound:
            ta_network = docker_client.networks.create(therapeutic_area_info.name + "-net", check_duplicate=True)
        install_container = docker_client.containers.get("feder8-installer")

        try:
            ta_network.connect(install_container)
        except docker.errors.APIError:
            pass

        registry = therapeutic_area_info.registry

        configuration:ConfigurationController = ConfigurationController(therapeutic_area, current_environment, is_windows)
        if email is None:
            email = configuration.get_configuration('feder8.central.service.image-repo-username')
        if cli_key is None:
            cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')
    except KeyboardInterrupt:
        sys.exit(1)

    network_names = [therapeutic_area.lower() + '-net']
    volume_names = ['feder8-config-server']
    container_names = ['nginx', 'config-server-update-configuration']

    networks = check_networks_and_create_if_not_exists(docker_client, network_names)
    volumes = check_volumes_and_create_if_not_exists(docker_client, volume_names)
    check_containers_and_remove_if_not_exists(docker_client, container_names)

    init_config_repo = '/'.join([registry.registry_url, registry.project, 'config-server'])
    init_config_tag = 'update-configuration-2.0.0'
    init_config_image = ':'.join([init_config_repo, init_config_tag])
    pull_image(docker_client,registry, init_config_image, email, cli_key)

    print('Updating configuration in config-server...')
    environment_variables = {
        'FEDER8_CONFIG_SERVER_THERAPEUTIC_AREA': therapeutic_area_info.name,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO': registry.registry_url,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-USERNAME': email,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-KEY': cli_key
    }
    run_container(
        docker_client=docker_client,
        image=init_config_image,
        remove=True,
        name=container_names[1],
        environment=environment_variables,
        network=network_names[0],
        volumes={
            volume_names[0]: {
                'bind': '/home/feder8/config-repo',
                'mode': 'rw'
            }
        },
        detach=True,
        show_logs=True)

    try:
        docker_client.containers.get("local-portal")
        url = 'http://local-portal/portal/actuator/refresh'
        requests.post(url)
    except docker.errors.NotFound:
        pass

    print('Done updating configuration in config-server')

    nginx_repo = '/'.join([registry.registry_url, registry.project, 'nginx'])
    nginx_tag = '2.0.4'
    nginx_image = ':'.join([nginx_repo, nginx_tag])

    pull_image(docker_client, registry, nginx_image, email, cli_key)

    print('Starting Nginx container...')
    environment_variables = {
        'HONEUR_THERAPEUTIC_AREA': therapeutic_area_info.name
    }

    container = docker_client.containers.run(
        image=nginx_image,
        name=container_names[0],
        restart_policy={"Name": "always"},
        security_opt=['no-new-privileges'],
        ports={
            '8080/tcp': 80
        },
        remove=False,
        environment=environment_variables,
        network=network_names[0],
        volumes={},
        detach=True
    )

    print('Done starting Nginx container')

    wait_for_healthy_container(docker_client, container, 5, 120)


@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
def clean(therapeutic_area):
    try:
        current_environment = os.getenv('CURRENT_DIRECTORY', '')
        is_windows = os.getenv('IS_WINDOWS', 'false') == 'true'
        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        try:
            docker_client = docker.from_env(timeout=3000)
        except docker.errors.DockerException:
            print('Error while fetching docker api... Is docker running?')
            sys.exit(1)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        try:
            ta_network = docker_client.networks.get(therapeutic_area_info.name + "-net")
        except docker.errors.NotFound:
            ta_network = docker_client.networks.create(therapeutic_area_info.name + "-net", check_duplicate=True)
        install_container = docker_client.containers.get("feder8-installer")

        try:
            ta_network.connect(install_container)
        except docker.errors.APIError:
            pass

        confirm_continue = questionary.confirm("This script is about to delete everything installed related to " + therapeutic_area + ". Are you sure to continue?").unsafe_ask()

        if not confirm_continue:
            sys.exit(1)
    except KeyboardInterrupt:
        sys.exit(1)

    ta_network_name = therapeutic_area_info.name + '-net'
    try:
        ta_network = docker_client.networks.get(ta_network_name)
    except docker.errors.NotFound:
        return
    for container in ta_network.containers:
        if container.attrs['Name'] != '/feder8-installer':
            continue
        elif container.attrs['Name'] != '/config-server':
            print('Stopping and removing ' + container.attrs['Name'])
            container.stop()
            try:
                container.remove(v=True)
            except docker.errors.NotFound:
                pass
        else:
            config_server_networks = container.attrs['NetworkSettings']['Networks'].keys()
            if len(config_server_networks) == 1:
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


    try:
        docker_client.volumes.get("shared").remove()
    except docker.errors.NotFound:
        pass
    try:
        docker_client.volumes.get("pgdata").remove()
    except docker.errors.NotFound:
        pass
    try:
        ta_network.remove()
    except docker.errors.NotFound:
        pass

@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
def backup(therapeutic_area):
    print("Creating backup of running database postgres... This could take a while")
    try:
        current_environment = os.getenv('CURRENT_DIRECTORY', '')
        is_windows = os.getenv('IS_WINDOWS', 'false') == 'true'
        directory_separator = '/'
        if is_windows:
            directory_separator = '\\'
        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        try:
            docker_client = docker.from_env(timeout=3000)
        except docker.errors.DockerException:
            print('Error while fetching docker api... Is docker running?')
            sys.exit(1)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        try:
            ta_network = docker_client.networks.get(therapeutic_area_info.name + "-net")
        except docker.errors.NotFound:
            ta_network = docker_client.networks.create(therapeutic_area_info.name + "-net", check_duplicate=True)
        install_container = docker_client.containers.get("feder8-installer")

        try:
            ta_network.connect(install_container)
        except docker.errors.APIError:
            pass
    except KeyboardInterrupt:
        sys.exit(1)

    try:
        postgres_container = docker_client.containers.get("postgres")
    except docker.errors.NotFound:
        print("Postgres container not found. Could not create backup")
        sys.exit(1)
    postgres_version = postgres_container.attrs['Config']['Image'].split(':')[1].split('-')[0]

    container = docker_client.containers.run(image="postgres:" + postgres_version,
                                            remove=False,
                                            name='postgres-database-backup',
                                            network=therapeutic_area_info.name + '-net',
                                            volumes={
                                                current_environment: {
                                                    'bind': '/opt/database',
                                                    'mode': 'rw'
                                                },
                                                'shared': {
                                                    'bind': '/var/lib/shared',
                                                    'mode': 'rw'
                                                }
                                            },
                                            command='bash -c \'set -e -o pipefail; echo "backing up OHDSI database... This could take a while"; source /var/lib/shared/honeur.env; export PGPASSWORD=${POSTGRES_PW}; cd /opt; pg_dump --create -h postgres -U postgres -f OHDSI.sql -d OHDSI; CURRENT_TIME=$(date "+%Y-%m-%d_%H-%M-%S"); tar -czf database/OHDSI_${CURRENT_TIME}.tar.gz OHDSI.sql; echo "Done backing up OHDSI database. File can be found at ' + current_environment + directory_separator + 'OHDSI-backup.gz"\'',
                                            detach=True)
    for l in container.logs(stream=True):
            print(l.decode('UTF-8'), end='')
    container.stop()
    container.remove(v=True)

@init.command()
def upgrade_database():
    try:
        docker_client = docker.from_env(timeout=3000)
    except docker.errors.DockerException:
        print('Error while fetching docker api... Is docker running?')
        sys.exit(1)


    new_pgdata_volume = docker_client.volumes.create("new-pgdata")
    postgres_container = docker_client.containers.get("postgres")
    postgres_container.stop()
    postgres_container.remove(v=True)

    container = docker_client.containers.run(image="postgres:13",
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

    container = docker_client.containers.run(image="tianon/postgres-upgrade:9.6-to-13",
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


    pgdata_volume = docker_client.volumes.get("pgdata")
    pgdata_volume.remove()

    docker_client.volumes.create("pgdata")

    container = docker_client.containers.run(image="alpine",
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
@click.option('-u', '--username')
@click.option('-p', '--password')
@click.pass_context
def essentials(ctx, therapeutic_area, email, cli_key, user_password, admin_password, host, security_method, ldap_url, ldap_dn, ldap_base_dn, ldap_system_username, ldap_system_password, log_directory, notebook_directory, username, password):
    try:
        current_environment = os.getenv('CURRENT_DIRECTORY', '')
        is_windows = os.getenv('IS_WINDOWS', 'false') == 'true'
        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        try:
            docker_client = docker.from_env(timeout=3000)
        except docker.errors.DockerException:
            print('Error while fetching docker api... Is docker running?')
            sys.exit(1)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        try:
            ta_network = docker_client.networks.get(therapeutic_area_info.name + "-net")
        except docker.errors.NotFound:
            ta_network = docker_client.networks.create(therapeutic_area_info.name + "-net", check_duplicate=True)
        install_container = docker_client.containers.get("feder8-installer")

        try:
            ta_network.connect(install_container)
        except docker.errors.APIError:
            pass

        try:
            docker_client.volumes.get("pgdata")
            clean_install = questionary.confirm("A previous installation was found on your system. Would you like to remove the previous installation?").unsafe_ask()
            if clean_install:
                backup_pgdata = questionary.confirm("Would you like to create a backup file of your database first?").unsafe_ask()
                if backup_pgdata:
                    ctx.invoke(backup, therapeutic_area=therapeutic_area)
                ctx.invoke(clean, therapeutic_area=therapeutic_area)
            else:
                postgres_container = docker_client.containers.get("postgres")
                postgres_version = postgres_container.attrs['Config']['Image'].split(':')[1]
                if '9.6' in postgres_version:
                    backup_pgdata = questionary.confirm("The new installation will provide an upgraded database. Would you like to create a backup file of your database before upgrading?").unsafe_ask()
                    if backup_pgdata:
                        ctx.invoke(backup, therapeutic_area=therapeutic_area)
                    ctx.invoke(upgrade_database)
        except docker.errors.NotFound:
            pass

        configuration:ConfigurationController = ConfigurationController(therapeutic_area, current_environment, is_windows)
        if email is None:
            email = configuration.get_configuration('feder8.central.service.image-repo-username')
        if cli_key is None:
            cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')
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

        if security_method != 'None':
            if username is None:
                username = configuration.get_configuration('feder8.local.security.user-mgmt-username')

            if password is None:
                password = configuration.get_configuration('feder8.local.security.user-mgmt-password')
    except KeyboardInterrupt:
        sys.exit(1)

    ctx.invoke(postgres, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key, user_password=user_password, admin_password=admin_password)
    ctx.invoke(local_portal, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key, host=host)
    ctx.invoke(atlas_webapi, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key, host=host, security_method=security_method, ldap_url=ldap_url, ldap_dn=ldap_dn, ldap_base_dn=ldap_base_dn, ldap_system_username=ldap_system_username, ldap_system_password=ldap_system_password)
    ctx.invoke(zeppelin, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key, log_directory=log_directory, notebook_directory=notebook_directory, security_method=security_method, ldap_url=ldap_url, ldap_dn=ldap_dn, ldap_base_dn=ldap_base_dn, ldap_system_username=ldap_system_username, ldap_system_password=ldap_system_password)
    if security_method != 'None':
        ctx.invoke(user_management, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key, username=username, password=password)
    ctx.invoke(nginx, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key)

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
@click.pass_context
def full(ctx, therapeutic_area, email, cli_key, user_password, admin_password, host, security_method, ldap_url, ldap_dn, ldap_base_dn, ldap_system_username, ldap_system_password, log_directory, notebook_directory, feder8_studio_directory, username, password, organization):
    try:
        current_environment = os.getenv('CURRENT_DIRECTORY', '')
        is_windows = os.getenv('IS_WINDOWS', 'false') == 'true'
        if therapeutic_area is None:
            therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).unsafe_ask()

        try:
            docker_client = docker.from_env(timeout=3000)
        except docker.errors.DockerException:
            print('Error while fetching docker api... Is docker running?')
            sys.exit(1)

        therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]

        try:
            ta_network = docker_client.networks.get(therapeutic_area_info.name + "-net")
        except docker.errors.NotFound:
            ta_network = docker_client.networks.create(therapeutic_area_info.name + "-net", check_duplicate=True)
        install_container = docker_client.containers.get("feder8-installer")

        try:
            ta_network.connect(install_container)
        except docker.errors.APIError:
            pass

        try:
            docker_client.volumes.get("pgdata")
            clean_install = questionary.confirm("A previous installation was found on your system. Would you like to remove the previous installation?").unsafe_ask()
            if clean_install:
                backup_pgdata = questionary.confirm("Would you like to create a backup file of your database first?").unsafe_ask()
                if backup_pgdata:
                    ctx.invoke(backup, therapeutic_area=therapeutic_area)
                ctx.invoke(clean, therapeutic_area=therapeutic_area)
            else:
                postgres_container = docker_client.containers.get("postgres")
                postgres_version = postgres_container.attrs['Config']['Image'].split(':')[1]
                if '9.6' in postgres_version:
                    backup_pgdata = questionary.confirm("The new installation will provide an upgraded database. Would you like to create a backup file of your database before upgrading?").unsafe_ask()
                    if backup_pgdata:
                        ctx.invoke(backup, therapeutic_area=therapeutic_area)
                    ctx.invoke(upgrade_database, therapeutic_area=therapeutic_area)
        except docker.errors.NotFound:
            pass


        configuration:ConfigurationController = ConfigurationController(therapeutic_area, current_environment, is_windows)
        if email is None:
            email = configuration.get_configuration('feder8.central.service.image-repo-username')
        if cli_key is None:
            cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')
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

        if feder8_studio_directory is None:
            feder8_studio_directory = configuration.get_configuration('feder8.local.host.feder8-studio-directory')

        if security_method != 'None':
            if username is None:
                username = configuration.get_configuration('feder8.local.security.user-mgmt-username')

            if password is None:
                password = configuration.get_configuration('feder8.local.security.user-mgmt-password')

        if organization is None:
            organization = questionary.select("Name of organization?", choices=therapeutic_area_info.organizations).unsafe_ask()
    except KeyboardInterrupt:
        sys.exit(1)

    ctx.invoke(postgres, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key, user_password=user_password, admin_password=admin_password)
    ctx.invoke(local_portal, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key, host=host)
    ctx.invoke(atlas_webapi, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key, host=host, security_method=security_method, ldap_url=ldap_url, ldap_dn=ldap_dn, ldap_base_dn=ldap_base_dn, ldap_system_username=ldap_system_username, ldap_system_password=ldap_system_password)
    ctx.invoke(zeppelin, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key, log_directory=log_directory, notebook_directory=notebook_directory, security_method=security_method, ldap_url=ldap_url, ldap_dn=ldap_dn, ldap_base_dn=ldap_base_dn, ldap_system_username=ldap_system_username, ldap_system_password=ldap_system_password)
    if security_method != 'None':
        ctx.invoke(user_management, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key, username=username, password=password)
    ctx.invoke(distributed_analytics, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key, organization=organization)
    ctx.invoke(feder8_studio, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key, host=host, feder8_studio_directory=feder8_studio_directory, security_method=security_method, ldap_url=ldap_url, ldap_dn=ldap_dn, ldap_base_dn=ldap_base_dn, ldap_system_username=ldap_system_username, ldap_system_password=ldap_system_password)
    ctx.invoke(nginx, therapeutic_area=therapeutic_area, email=email, cli_key=cli_key)