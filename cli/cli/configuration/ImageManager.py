import docker
import os, sys
from docker.client import DockerClient
from cli.configuration.ImageLookup import *
from cli.registry.registry import Registry


def pull_all_images(docker_client: DockerClient, email, cli_key, therapeutic_area_info):
    registry = therapeutic_area_info.registry
    images = get_all_feder8_local_image_name_tags(therapeutic_area_info)
    images.append(get_postgres_13_image_name_tag())
    for image in images:
        pull_image(docker_client=docker_client, registry=registry, image=image, email=email, cli_key=cli_key)
    return images


def pull_image(docker_client: DockerClient, registry: Registry, image: str, email: str, cli_key: str, restricted=False):
    print(f'Pulling image {image} ...')
    try:
        docker_client.login(username=email, password=cli_key, registry=registry.registry_url, reauth=True)
    except docker.errors.APIError:
        if restricted:
            print(f'Failed to pull image {image}. Please check the provided email and CLI Key. '
                  f'Access to this image is restricted. '
                  f'Please request access if needed and re-run the installation script.')
        else:
            print('Failed to pull image. Are the correct email and CLI Key provided?')
        sys.exit(1)
    docker_client.images.pull(image)
    print(f'Done pulling image {image}')


def export_all_images(docker_client: DockerClient, email, cli_key, therapeutic_area_info):
    images = pull_all_images(docker_client=docker_client, email=email, cli_key=cli_key, therapeutic_area_info=therapeutic_area_info)
    export_files = []
    for image in images:
        export_files.append(export_image(docker_client=docker_client, image_name_tag=image))
    return export_files


def export_image(docker_client: DockerClient, image_name_tag: str, target_folder = "images"):
    image = docker_client.images.get(image_name_tag)
    export_file_path = get_export_file_path(image_name_tag, target_folder=target_folder)
    with open(export_file_path, 'wb') as tarfile:
        for chunk in image.save(named=True):
            tarfile.write(chunk)
    return export_file_path


def get_export_file_path(image_name_tag: str, target_folder):
    script_dir = os.path.dirname(os.path.realpath('__file__'))
    if not os.path.exists(target_folder):
        os.makedirs(target_folder)
    filename = (image_name_tag.rpartition('/')[-1]).partition(":")[0]
    return os.path.join(script_dir, f'{target_folder}/{filename}.tar')


def load_image(docker_client: DockerClient, image_filename):
    try:
        with open(image_filename, mode='rb') as image_file:
            images = docker_client.images.load(image_file)
        logging.info("The following images are successfully loaded:")
        for image in images:
            logging.info(image.tags)
    except Exception as e:
        logging.error("Failed to load the Docker images:")
        logging.error(e)
