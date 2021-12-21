import logging
import docker
from docker.client import DockerClient
from cli.therapeutic_area.therapeutic_area import TherapeuticArea
from cli.registry.registry import Registry

class DockerClientFacade:

    def __init__(self, therapeutic_area_info: TherapeuticArea, email, cli_key, docker_client=None):
        self._therapeutic_area_info = therapeutic_area_info
        self._email = email
        self._cli_key = cli_key
        self._registry = therapeutic_area_info.registry
        if docker_client:
            self._docker_client = docker_client
        else:
            self._docker_client = docker.from_env(timeout=3000)
        self._docker_client.login(username=self._email,
                                  password=self._cli_key,
                                  registry=self._registry.registry_url)

    @property
    def therapeutic_area_info(self) -> TherapeuticArea:
        return self._therapeutic_area_info

    @property
    def registry(self) -> Registry:
        return self._registry

    @property
    def docker_client(self) -> DockerClient:
        return self._docker_client

    def get_network_name(self):
        return self._therapeutic_area_info.name.lower() + "-net"

    def get_image_name_tag(self, name, tag):
        image_name = '/'.join([self.registry.registry_url, self.registry.project, name])
        return f'{image_name}:{tag}'

    def pull_image(self, image: str):
        logging.info(f'Pulling image {image} ...')
        self._docker_client.images.pull(image)
        logging.info(f'Done pulling image {image}')

    def run_container(self, image: str, remove: bool, name: str,
                      environment, network: str, volumes,
                      detach: bool, show_logs: bool):
        container = self._docker_client.containers.run(image=image, remove=remove, name=name,
                                                       environment=environment, network=network, volumes=volumes,
                                                       detach=detach)
        if show_logs:
            for l in container.logs(stream=True):
                print(l.decode('UTF-8'), end='')
        return container

