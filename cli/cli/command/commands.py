from cli.registry.registry import Registry
from cli.configuration.configuration_controller import ConfigurationController
import sys
import time
from typing import Container

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

def check_network_and_create_if_not_exists(docker_client:DockerClient, network:str):
    if len(docker_client.networks.list(filters={"name":network})) == 0:
        print(' '.join([network,'docker network does not exists.']))
        print(' '.join(['Creating',network,'docker network...']))
        docker_client.networks.create(network, driver="bridge")
        print(' '.join(['Done creating',network,'docker network']))

def check_volume_and_create_if_not_exists(docker_client:DockerClient, volume:str):
    if len(docker_client.volumes.list(filters={"name":volume})) == 0:
        print(' '.join([volume,'docker volume does not exists.']))
        print(' '.join(['Creating',volume,'docker volume...']))
        docker_client.volumes.create(volume)
        print(' '.join(['Done creating',volume,'docker volume']))

def check_container_and_remove_if_not_exists(docker_client:DockerClient, container_name:str):
    if len(docker_client.containers.list(all=True, filters={"name":container_name})) > 0:
        print(' '.join([container_name,'is running.']))
        print(' '.join(['Removing',container_name,'container...']))
        container = docker_client.containers.get(container_name)
        container.stop()
        container.remove()
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
def postgres(therapeutic_area, email, cli_key):
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
