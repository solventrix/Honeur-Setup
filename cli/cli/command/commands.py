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
def config_server(therapeutic_area, email, cli_key):
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

    print('Updating initial configuration in config-server...')
    run_container(
        docker_client=docker_client,
        image=init_config_image,
        remove=True,
        name=container_names[1],
        environment={
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

    print('Done updating initial configuration in config-server')



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
    volume_names = ['pgdata', 'feder8-config-server']
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

    print('Updating database configuration in config-server...')
    run_container(
        docker_client=docker_client,
        image=init_config_image,
        remove=True,
        name=container_names[1],
        environment={
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
            volume_names[1]: {
                'bind': '/home/feder8/config-repo',
                'mode': 'rw'
            }
        },
        detach=True,
        show_logs=True)

    print('Done updating database configuration in config-server')

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
def atlas_webapi(therapeutic_area, email, cli_key):
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
def zeppelin(therapeutic_area, email, cli_key):
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
