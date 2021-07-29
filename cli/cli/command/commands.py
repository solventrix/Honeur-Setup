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
        if len(docker_client.containers.list(all=True, filters={"name":container_name})) > 0:
            print(' '.join([container_name,'is running.']))
            print(' '.join(['Removing',container_name,'container...']))
            container = docker_client.containers.get(container_name)
            container.stop()
            container.remove(v=True)
            print(' '.join(['Done removing',container_name,'container...']))

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
@click.option('-h', '--host')
def config_server(therapeutic_area, email, cli_key, host):
    if therapeutic_area is None:
        therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).ask()

    configuration:ConfigurationController = ConfigurationController(therapeutic_area)
    if email is None:
        email = configuration.get_configuration('feder8.central.service.image-repo-username')
    if cli_key is None:
        cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')
    if host is None:
        host = configuration.get_configuration('feder8.local.host.name')
    try:
        docker_client = docker.from_env()
    except docker.errors.DockerException:
        print('Error while fetching docker api... Is docker running?')
        sys.exit(1)

    network_names = ['feder8-net']
    volume_names = ['feder8-config-server']
    container_names = ['config-server', 'config-server-update-configuration']

    therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]
    registry = therapeutic_area_info.registry
    repo = '/'.join([registry.registry_url, registry.project, 'config-server'])
    tag = '2.0.0'
    image = ':'.join([repo, tag])

    check_networks_and_create_if_not_exists(docker_client, network_names)
    check_volumes_and_create_if_not_exists(docker_client, volume_names)
    check_containers_and_remove_if_not_exists(docker_client, container_names)

    pull_image(docker_client,registry, image, email, cli_key)

    print('Starting config-server container...')
    container = docker_client.containers.run(
        image=image,
        name=container_names[0],
        restart_policy={"Name": "always"},
        security_opt=['no-new-privileges'],
        remove=False,
        environment={},
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
            'FEDER8_LOCAL_HOST_NAME': host,
            'FEDER8_CENTRAL_SERVICE_IMAGE-REPO': registry.registry_url,
            'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-USERNAME': email,
            'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-KEY': cli_key,
            'FEDER8_CENTRAL_SERVICE_OAUTH-ISSUER-URI': 'https://' + therapeutic_area_info.cas_url,
            'FEDER8_CENTRAL_SERVICE_OAUTH-CLIENT-ID': 'feder8-local',
            'FEDER8_CENTRAL_SERVICE_OAUTH-CLIENT-SECRET': 'feder8-local-secret',
            'FEDER8_CENTRAL_SERVICE_OAUTH-USERNAME': email,
            'FEDER8_CENTRAL_SERVICE_CATALOGUE-BASE-URI': 'https://' + therapeutic_area_info.catalogue_url
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

    print('Done updating configuration in config-server')


@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
@click.option('-e', '--email')
@click.option('-k', '--cli-key')
@click.option('-up', '--user-password')
@click.option('-ap', '--admin-password')
def postgres(therapeutic_area, email, cli_key, user_password, admin_password):
    if therapeutic_area is None:
        therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).ask()

    configuration:ConfigurationController = ConfigurationController(therapeutic_area)
    if email is None:
        email = configuration.get_configuration('feder8.central.service.image-repo-username')
    if cli_key is None:
        cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')
    if user_password is None:
        user_password = configuration.get_configuration('feder8.local.datasource.password')
    if admin_password is None:
        admin_password = configuration.get_configuration('feder8.local.datasource.admin-password')

    try:
        docker_client = docker.from_env(timeout=3000)
    except docker.errors.DockerException:
        print('Error while fetching docker api... Is docker running?')
        sys.exit(1)

    network_names = ['feder8-net', therapeutic_area.lower() + '-net']
    volume_names = ['pgdata', 'shared', 'feder8-config-server']
    container_names = ['postgres', 'config-server-update-configuration']

    therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]
    registry = therapeutic_area_info.registry
    repo = '/'.join([registry.registry_url, registry.project, 'postgres'])
    tag = '9.6-omopcdm-5.3.1-webapi-2.7.1-2.0.2'
    image = ':'.join([repo, tag])

    networks = check_networks_and_create_if_not_exists(docker_client, network_names)
    volumes = check_volumes_and_create_if_not_exists(docker_client, volume_names)
    check_containers_and_remove_if_not_exists(docker_client, container_names)

    pull_image(docker_client,registry, image, email, cli_key)

    print('Starting postgres container...')
    docker_client
    container = docker_client.containers.run(
        image=image,
        name=container_names[0],
        ports={
            '5432/tcp': 5444
        },
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
                'bind': '/home/feder8/config-repo',
                'mode': 'rw'
            },
            volume_names[1]: {
                'bind': '/var/lib/postgresql/envfileshared',
                'mode': 'rw'
            }
        },
        detach=True
    )
    networks[1].connect(container)

    print('Done starting postgres container')

    wait_for_healthy_container(docker_client, container, 5, 120)

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

    print('Done updating configuration in config-server')

@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
@click.option('-e', '--email')
@click.option('-k', '--cli-key')
def local_portal(therapeutic_area, email, cli_key):
    if therapeutic_area is None:
        therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).ask()

    configuration:ConfigurationController = ConfigurationController(therapeutic_area)
    if email is None:
        email = configuration.get_configuration('feder8.central.service.image-repo-username')
    if cli_key is None:
        cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')

    try:
        docker_client = docker.from_env(timeout=3000)
    except docker.errors.DockerException:
        print('Error while fetching docker api... Is docker running?')
        sys.exit(1)

    network_names = ['feder8-net', therapeutic_area.lower() + '-net']
    volume_names = ['shared', 'feder8-config-server']
    container_names = ['local-portal', 'config-server-update-configuration']

    therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]
    registry = therapeutic_area_info.registry
    repo = '/'.join([registry.registry_url, registry.project, 'local-portal'])
    tag = '2.0.0'
    image = ':'.join([repo, tag])

    networks = check_networks_and_create_if_not_exists(docker_client, network_names)
    volumes = check_volumes_and_create_if_not_exists(docker_client, volume_names)
    check_containers_and_remove_if_not_exists(docker_client, container_names)

    pull_image(docker_client,registry, image, email, cli_key)

    print('Starting local-portal container...')
    container = docker_client.containers.run(
        image=image,
        name=container_names[0],
        ports={
            '8080/tcp': 8080
        },
        restart_policy={"Name": "always"},
        security_opt=['no-new-privileges'],
        remove=False,
        environment={
            'FEDER8_THERAPEUTIC_AREA_NAME': therapeutic_area_info.name,
            'FEDER8_THERAPEUTIC_AREA_LIGHT_THEME_COLOR': therapeutic_area_info.light_theme,
            'FEDER8_THERAPEUTIC_AREA_DARK_THEME_COLOR': therapeutic_area_info.dark_theme,
            'FEDER8_CONFIG_SERVER_USERNAME': 'root',
            'FEDER8_CONFIG_SERVER_HOST': 'config-server',
            'FEDER8_CONFIG_SERVER_PORT': '8080'
        },
        network=network_names[0],
        volumes={
            volume_names[1]: {
                'bind': '/var/lib/shared',
                'mode': 'ro'
            },
            volume_names[1]: {
                'bind': '/home/feder8/config-repo',
                'mode': 'rw'
            }
        },
        detach=True
    )
    networks[1].connect(container)

    print('Done starting local-portal container')

    wait_for_healthy_container(docker_client, container, 5, 120)

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
            'FEDER8_CENTRAL_SERVICE_IMAGE-REPO': registry.registry_url,
            'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-USERNAME': email,
            'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-KEY': cli_key,
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

    print('Done updating configuration in config-server')

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
    if therapeutic_area is None:
        therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).ask()

    configuration:ConfigurationController = ConfigurationController(therapeutic_area)
    if email is None:
        email = configuration.get_configuration('feder8.central.service.image-repo-username')
    if cli_key is None:
        cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')

    if host is None:
        host = configuration.get_configuration('feder8.local.host.name')

    if security_method is None:
        security_method = configuration.get_configuration('feder8.local.security.security-method')

    if security_method is 'LDAP':
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

    try:
        docker_client = docker.from_env(timeout=3000)
    except docker.errors.DockerException:
        print('Error while fetching docker api... Is docker running?')
        sys.exit(1)

    network_names = ['feder8-net', therapeutic_area.lower() + '-net']
    volume_names = ['shared', 'feder8-config-server']
    container_names = ['webapi', 'atlas', 'config-server-update-configuration']

    therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]
    registry = therapeutic_area_info.registry
    webapi_repo = '/'.join([registry.registry_url, registry.project, 'webapi'])
    webapi_tag = '2.9.0-2.0.0'
    webapi_image = ':'.join([webapi_repo, webapi_tag])

    networks = check_networks_and_create_if_not_exists(docker_client, network_names)
    volumes = check_volumes_and_create_if_not_exists(docker_client, volume_names)
    check_containers_and_remove_if_not_exists(docker_client, container_names)

    pull_image(docker_client, registry, webapi_image, email, cli_key)

    print('Starting WebAPI container...')
    environment_variables = {
        'DB_HOST': 'postgres',
        'FEDER8_WEBAPI_CENTRAL': 'false',
    }
    if security_method is 'None':
        environment_variables['FEDER8_WEBAPI_SECURE'] = 'false'
    else:
        environment_variables['FEDER8_WEBAPI_SECURE'] = 'true'
        if security_method is 'LDAP':
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
    networks[1].connect(container)

    print('Done starting WebAPI container')

    wait_for_healthy_container(docker_client, container, 5, 120)

    atlas_repo = '/'.join([registry.registry_url, registry.project, 'atlas'])
    atlas_tag = '2.9.0-2.0.0'
    atlas_image = ':'.join([atlas_repo, atlas_tag])
    pull_image(docker_client,registry, atlas_image, email, cli_key)

    print('Starting Atlas container...')
    environment_variables = {
        'FEDER8_WEBAPI_URL': 'http://' + host + '/WebAPI/',
        'FEDER8_ATLAS_CENTRAL': 'false',
    }
    if security_method is 'None':
        environment_variables['FEDER8_ATLAS_SECURE'] = 'false'
    else:
        environment_variables['FEDER8_ATLAS_SECURE'] = 'true'
        if security_method is 'LDAP':
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
    networks[1].connect(container)

    print('Done starting Atlas container')

    wait_for_healthy_container(docker_client, container, 5, 120)

    init_config_repo = '/'.join([registry.registry_url, registry.project, 'config-server'])
    init_config_tag = 'update-configuration-2.0.0'
    init_config_image = ':'.join([init_config_repo, init_config_tag])
    pull_image(docker_client,registry, init_config_image, email, cli_key)

    print('Updating configuration in config-server...')
    environment_variables = {
        'FEDER8_LOCAL_HOST_NAME': host,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO': registry.registry_url,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-USERNAME': email,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-KEY': cli_key,
    }
    if security_method is 'None':
        environment_variables['FEDER8_LOCAL_SECURITY_SECURITY-METHOD'] = 'None'
    else:
        if security_method is 'LDAP':
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

    print('Done updating configuration in config-server')


@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
@click.option('-e', '--email')
@click.option('-k', '--cli-key')
@click.option('-ld', '--log-directory')
@click.option('-nd', '--notebook-directory')
@click.option('-dd', '--data-directory')
@click.option('-s', '--security-method', type=click.Choice(['None', 'JDBC', 'LDAP']))
@click.option('-lu', '--ldap-url')
@click.option('-ldn', '--ldap-dn')
@click.option('-lbdn', '--ldap-base-dn')
@click.option('-lsu', '--ldap-system-username')
@click.option('-lsp', '--ldap-system-password')
def zeppelin(therapeutic_area, email, cli_key, log_directory, notebook_directory, data_directory, security_method, ldap_url, ldap_dn, ldap_base_dn, ldap_system_username, ldap_system_password):
    if therapeutic_area is None:
        therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).ask()

    configuration:ConfigurationController = ConfigurationController(therapeutic_area)
    if email is None:
        email = configuration.get_configuration('feder8.central.service.image-repo-username')
    if cli_key is None:
        cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')

    if log_directory is None:
        log_directory = configuration.get_configuration('feder8.local.host.log-directory')

    if notebook_directory is None:
        notebook_directory = configuration.get_configuration('feder8.local.host.notebook-directory')

    if data_directory is None:
        data_directory = configuration.get_configuration('feder8.local.host.data-directory')

    if security_method is None:
        security_method = configuration.get_configuration('feder8.local.security.security-method')

    if security_method is 'LDAP':
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

    try:
        docker_client = docker.from_env(timeout=3000)
    except docker.errors.DockerException:
        print('Error while fetching docker api... Is docker running?')
        sys.exit(1)

    network_names = ['feder8-net', therapeutic_area.lower() + '-net']
    volume_names = ['shared', 'feder8-config-server']
    container_names = ['zeppelin', 'config-server-update-configuration']

    therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]
    registry = therapeutic_area_info.registry
    webapi_repo = '/'.join([registry.registry_url, registry.project, 'zeppelin'])
    webapi_tag = '0.8.2-2.0.0'
    webapi_image = ':'.join([webapi_repo, webapi_tag])

    networks = check_networks_and_create_if_not_exists(docker_client, network_names)
    volumes = check_volumes_and_create_if_not_exists(docker_client, volume_names)
    check_containers_and_remove_if_not_exists(docker_client, container_names)

    pull_image(docker_client, registry, webapi_image, email, cli_key)

    print('Starting Zeppelin container...')
    environment_variables = {
        'ZEPPELIN_NOTEBOOK_DIR': '/notebook',
        'FEDER8_WEBAPI_CENTRAL': 'false',
    }
    if security_method is 'LDAP':
        environment_variables['ZEPPELIN_SECURITY'] = 'ldap'
        environment_variables['LDAP_URL'] = ldap_url
        environment_variables['LDAP_DN'] = ldap_dn
        environment_variables['LDAP_BASE_DN'] = ldap_base_dn
    elif security_method is 'JDBC':
        environment_variables['ZEPPELIN_SECURITY'] = 'jdbc'
        environment_variables['LDAP_URL'] = 'ldap://localhost:389'
        environment_variables['LDAP_DN'] = 'dc=example,dc=org'
        environment_variables['LDAP_BASE_DN'] = 'cn=\{0\},dc=example,dc=org'

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
            },
            log_directory: {
                'bind': '/logs',
                'mode': 'rw'
            },
            notebook_directory: {
                'bind': '/notebook',
                'mode': 'rw'
            },
            data_directory: {
                'bind': '/usr/local/src/datafiles',
                'mode': 'rw'
            }
        },
        detach=True
    )
    networks[1].connect(container)

    print('Done starting WebAPI container')

    wait_for_healthy_container(docker_client, container, 5, 120)

    init_config_repo = '/'.join([registry.registry_url, registry.project, 'config-server'])
    init_config_tag = 'update-configuration-2.0.0'
    init_config_image = ':'.join([init_config_repo, init_config_tag])
    pull_image(docker_client,registry, init_config_image, email, cli_key)

    print('Updating configuration in config-server...')
    environment_variables = {
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO': registry.registry_url,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-USERNAME': email,
        'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-KEY': cli_key,
        'FEDER8_LOCAL_HOST_LOG-DIRECTORY': log_directory,
        'FEDER8_LOCAL_HOST_NOTEBOOK-DIRECTORY': notebook_directory,
        'FEDER8_LOCAL_HOST_DATA-DIRECTORY': data_directory
    }
    if security_method is 'None':
        environment_variables['FEDER8_LOCAL_SECURITY_SECURITY-METHOD'] = 'None'
    else:
        if security_method is 'LDAP':
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
            volume_names[1]: {
                'bind': '/home/feder8/config-repo',
                'mode': 'rw'
            }
        },
        detach=True,
        show_logs=True)

    print('Done updating configuration in config-server')


@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
@click.option('-e', '--email')
@click.option('-k', '--cli-key')
def user_management(therapeutic_area, email, cli_key):
    if therapeutic_area is None:
        therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).ask()

    configuration:ConfigurationController = ConfigurationController(therapeutic_area)
    if email is None:
        email = configuration.get_configuration('feder8.central.service.image-repo-username')
    if cli_key is None:
        cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')

    try:
        docker_client = docker.from_env()
    except docker.errors.DockerException:
        print('Error while fetching docker api... Is docker running?')
        sys.exit(1)

    network = 'feder8-net'
    volume = 'feder8-config-server'
    name = 'config-server'

    therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]
    registry = therapeutic_area_info.registry
    repo = '/'.join([registry.registry_url, registry.project, 'config-server'])
    tag = '2.0.0'
    image = ':'.join([repo, tag])

    check_network_and_create_if_not_exists(docker_client, network)
    check_volume_and_create_if_not_exists(docker_client, volume)
    check_container_and_remove_if_not_exists(docker_client, name)


    pull_image(docker_client,registry, image, email, cli_key)

    print('Starting config-server container...')
    container = docker_client.containers.run(
        image=image,
        name=name,
        restart_policy={"Name": "always"},
        security_opt=['no-new-privileges'],
        remove=False,
        environment={},
        network=network,
        volumes={
            volume: {
                'bind': '/home/feder8/config-repo',
                'mode': 'rw'
            }
        },
        detach=True
    )

    print('Done starting config-server container')

    wait_for_healthy_container(docker_client, container, 5, 120)

    init_config_tag = 'update-configuration-2.0.0'
    init_config_image = ':'.join([repo, init_config_tag])
    pull_image(docker_client,registry, init_config_image, email, cli_key)

    print('Updating initial configuration in config-server...')
    run_container(
        docker_client=docker_client,
        image=init_config_image,
        remove=True,
        name='config-server-add-configuration',
        environment={
            'FEDER8_CENTRAL_SERVICE_IMAGE-REPO': registry.registry_url,
            'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-USERNAME': email,
            'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-KEY': cli_key,
            'FEDER8_CENTRAL_SERVICE_OAUTH-ISSUER_URI': 'http://' + therapeutic_area_info.cas_url,
            'FEDER8_CENTRAL_SERVICE_OAUTH-CLIENT-ID': 'feder8-local',
            'FEDER8_CENTRAL_SERVICE_OAUTH-CLIENT-SECRET': 'feder8-local-secret',
            'FEDER8_CENTRAL_SERVICE_OAUTH-USERNAME': email,
            'FEDER8_CENTRAL_SERVICE_CATALOGUE-BASE-URI': 'https://' + therapeutic_area_info.catalogue_url
        },
        network=network,
        volumes={
            volume: {
                'bind': '/home/feder8/config-repo',
                'mode': 'rw'
            }
        },
        detach=True,
        show_logs=True)

    print('Done updating initial configuration in config-server')


@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
@click.option('-e', '--email')
@click.option('-k', '--cli-key')
def distributed_analytics(therapeutic_area, email, cli_key):
    if therapeutic_area is None:
        therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).ask()

    configuration:ConfigurationController = ConfigurationController(therapeutic_area)
    if email is None:
        email = configuration.get_configuration('feder8.central.service.image-repo-username')
    if cli_key is None:
        cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')

    try:
        docker_client = docker.from_env()
    except docker.errors.DockerException:
        print('Error while fetching docker api... Is docker running?')
        sys.exit(1)

    network = 'feder8-net'
    volume = 'feder8-config-server'
    name = 'config-server'

    therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]
    registry = therapeutic_area_info.registry
    repo = '/'.join([registry.registry_url, registry.project, 'config-server'])
    tag = '2.0.0'
    image = ':'.join([repo, tag])

    check_network_and_create_if_not_exists(docker_client, network)
    check_volume_and_create_if_not_exists(docker_client, volume)
    check_container_and_remove_if_not_exists(docker_client, name)


    pull_image(docker_client,registry, image, email, cli_key)

    print('Starting config-server container...')
    container = docker_client.containers.run(
        image=image,
        name=name,
        restart_policy={"Name": "always"},
        security_opt=['no-new-privileges'],
        remove=False,
        environment={},
        network=network,
        volumes={
            volume: {
                'bind': '/home/feder8/config-repo',
                'mode': 'rw'
            }
        },
        detach=True
    )

    print('Done starting config-server container')

    wait_for_healthy_container(docker_client, container, 5, 120)

    init_config_tag = 'update-configuration-2.0.0'
    init_config_image = ':'.join([repo, init_config_tag])
    pull_image(docker_client,registry, init_config_image, email, cli_key)

    print('Updating initial configuration in config-server...')
    run_container(
        docker_client=docker_client,
        image=init_config_image,
        remove=True,
        name='config-server-add-configuration',
        environment={
            'FEDER8_CENTRAL_SERVICE_IMAGE-REPO': registry.registry_url,
            'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-USERNAME': email,
            'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-KEY': cli_key,
            'FEDER8_CENTRAL_SERVICE_OAUTH-ISSUER_URI': 'http://' + therapeutic_area_info.cas_url,
            'FEDER8_CENTRAL_SERVICE_OAUTH-CLIENT-ID': 'feder8-local',
            'FEDER8_CENTRAL_SERVICE_OAUTH-CLIENT-SECRET': 'feder8-local-secret',
            'FEDER8_CENTRAL_SERVICE_OAUTH-USERNAME': email,
            'FEDER8_CENTRAL_SERVICE_CATALOGUE-BASE-URI': 'https://' + therapeutic_area_info.catalogue_url
        },
        network=network,
        volumes={
            volume: {
                'bind': '/home/feder8/config-repo',
                'mode': 'rw'
            }
        },
        detach=True,
        show_logs=True)

    print('Done updating initial configuration in config-server')


@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.therapeutic_areas.keys()))
@click.option('-e', '--email')
@click.option('-k', '--cli-key')
def feder8_studio(therapeutic_area, email, cli_key):
    if therapeutic_area is None:
        therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.therapeutic_areas.keys()).ask()

    configuration:ConfigurationController = ConfigurationController(therapeutic_area)
    if email is None:
        email = configuration.get_configuration('feder8.central.service.image-repo-username')
    if cli_key is None:
        cli_key = configuration.get_configuration('feder8.central.service.image-repo-key')

    try:
        docker_client = docker.from_env()
    except docker.errors.DockerException:
        print('Error while fetching docker api... Is docker running?')
        sys.exit(1)

    network = 'feder8-net'
    volume = 'feder8-config-server'
    name = 'config-server'

    therapeutic_area_info = Globals.therapeutic_areas[therapeutic_area]
    registry = therapeutic_area_info.registry
    repo = '/'.join([registry.registry_url, registry.project, 'config-server'])
    tag = '2.0.0'
    image = ':'.join([repo, tag])

    check_network_and_create_if_not_exists(docker_client, network)
    check_volume_and_create_if_not_exists(docker_client, volume)
    check_container_and_remove_if_not_exists(docker_client, name)


    pull_image(docker_client,registry, image, email, cli_key)

    print('Starting config-server container...')
    container = docker_client.containers.run(
        image=image,
        name=name,
        restart_policy={"Name": "always"},
        security_opt=['no-new-privileges'],
        remove=False,
        environment={},
        network=network,
        volumes={
            volume: {
                'bind': '/home/feder8/config-repo',
                'mode': 'rw'
            }
        },
        detach=True
    )

    print('Done starting config-server container')

    wait_for_healthy_container(docker_client, container, 5, 120)

    init_config_tag = 'update-configuration-2.0.0'
    init_config_image = ':'.join([repo, init_config_tag])
    pull_image(docker_client,registry, init_config_image, email, cli_key)

    print('Updating initial configuration in config-server...')
    run_container(
        docker_client=docker_client,
        image=init_config_image,
        remove=True,
        name='config-server-add-configuration',
        environment={
            'FEDER8_CENTRAL_SERVICE_IMAGE-REPO': registry.registry_url,
            'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-USERNAME': email,
            'FEDER8_CENTRAL_SERVICE_IMAGE-REPO-KEY': cli_key,
            'FEDER8_CENTRAL_SERVICE_OAUTH-ISSUER_URI': 'http://' + therapeutic_area_info.cas_url,
            'FEDER8_CENTRAL_SERVICE_OAUTH-CLIENT-ID': 'feder8-local',
            'FEDER8_CENTRAL_SERVICE_OAUTH-CLIENT-SECRET': 'feder8-local-secret',
            'FEDER8_CENTRAL_SERVICE_OAUTH-USERNAME': email,
            'FEDER8_CENTRAL_SERVICE_CATALOGUE-BASE-URI': 'https://' + therapeutic_area_info.catalogue_url
        },
        network=network,
        volumes={
            volume: {
                'bind': '/home/feder8/config-repo',
                'mode': 'rw'
            }
        },
        detach=True,
        show_logs=True)

    print('Done updating initial configuration in config-server')
