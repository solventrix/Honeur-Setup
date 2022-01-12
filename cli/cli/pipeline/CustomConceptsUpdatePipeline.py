import logging
import psycopg2
from cli.configuration.DockerClientFacade import DockerClientFacade
from cli.configuration.DatabaseConnectionDetails import DatabaseConnectionDetails

class CustomConceptsUpdatePipeline:

    def __init__(self, docker_client: DockerClientFacade, db_connection_details: DatabaseConnectionDetails):
        self._docker_client = docker_client
        self._db_connection_details = db_connection_details

    def execute(self):
        logging.info("1. Pull all images of the pipeline")
        self._pull_images()
        logging.info("2. Update custom concepts")
        self._update_custom_concepts()
        logging.info("3. Rebuild concept hierarchy")
        self._rebuild_concept_hierarchy()

    def _pull_images(self):
        self._docker_client.pull_image(self.get_update_custom_concepts_image_name_tag())
        self._docker_client.pull_image(self.get_rebuild_concept_hierarchy_image_name_tag())

    def _update_custom_concepts(self):
        self._run_container(image=self.get_update_custom_concepts_image_name_tag(),
                            name='omopcdm-update-custom-concepts')

    def _rebuild_concept_hierarchy(self):
        self._run_container(image=self.get_rebuild_concept_hierarchy_image_name_tag(),
                            name='results-rebuild-concept-hierarchy')

    def _run_container(self, image, name):
        self._docker_client.run_container(image=image, remove=True, name=name,
                                          environment={'DB_HOST': 'postgres'},
                                          network=self.get_network_name(),
                                          volumes={'shared': {'bind': '/var/lib/shared', 'mode': 'rw'}},
                                          detach=True, show_logs=True)

    def get_update_custom_concepts_image_name_tag(self):
        return self._docker_client.get_image_name_tag('postgres', 'omopcdm-update-custom-concepts-2.4')

    def get_rebuild_concept_hierarchy_image_name_tag(self):
        return self._docker_client.get_image_name_tag('postgres', 'results-rebuild-concept-hierarchy-2.0.1')

    def get_network_name(self):
        return self._docker_client.get_network_name()