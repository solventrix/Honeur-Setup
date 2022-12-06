import logging
import psycopg2
from cli.configuration.DockerClientFacade import DockerClientFacade
from cli.configuration.DatabaseConnectionDetails import DatabaseConnectionDetails

class VocabularyUpdatePipeline:

    def __init__(self, docker_client: DockerClientFacade, db_connection_details: DatabaseConnectionDetails):
        self._docker_client = docker_client
        self._db_connection_details = db_connection_details

    def execute(self):
        logging.info("1. Pull all images of the pipeline")
        self._pull_images()
        logging.info("2. Delete base indexes")
        self._delete_base_indexes()
        logging.info("Delete constraints if needed")
        is_constraints_set = self._constraints_set()
        if is_constraints_set:
           logging.info("Constraints found")
           self._delete_constraints()
        else:
           logging.info("Constraints are not set")
        logging.info("4. Update vocabulary")
        self._update_vocabulary()
        logging.info("5. Update custom concepts")
        self._update_custom_concepts()
        logging.info("6. Add constraints when applicable")
        if is_constraints_set:
           self._add_constraints()
        logging.info("7. Add base indexes")
        self._add_base_indexes()
        logging.info("8. Rebuild concept hierarchy")
        self._rebuild_concept_hierarchy()

    def _constraints_set(self):
        logging.info("Checking if constraints are set...")
        try:
            if not self._db_connection_details.password or not self._db_connection_details.schema:
                logging.warning("Missing configuration, unable to check the DB constraints")
                return False

            with psycopg2.connect(host=self._db_connection_details.host,
                                  port=self._db_connection_details.port,
                                  dbname=self._db_connection_details.name,
                                  user=self._db_connection_details.username,
                                  password=self._db_connection_details.password,
                                  options="-c search_path=" + self._db_connection_details.schema) as connection:
                connection.autocommit = True
                with connection.cursor() as cursor:
                    cursor.execute("SELECT count(*) FROM pg_catalog.pg_constraint con INNER JOIN pg_catalog.pg_class rel ON rel.oid = con.conrelid INNER JOIN pg_catalog.pg_namespace nsp ON nsp.oid = connamespace WHERE nsp.nspname = 'omopcdm' AND rel.relname = 'concept' AND con.conname = 'fpk_concept_domain';")
                    return cursor.fetchone()[0] > 0
        except:
            logging.warning("Failed to check database constraints")
            return False

    def _pull_images(self):
        self._docker_client.pull_image(self.get_delete_base_indexes_image_name_tag())
        self._docker_client.pull_image(self.get_add_base_indexes_image_name_tag())
        self._docker_client.pull_image(self.get_delete_constraints_image_name_tag())
        self._docker_client.pull_image(self.get_add_constraints_image_name_tag())
        self._docker_client.pull_image(self.get_update_vocabulary_image_name_tag())
        self._docker_client.pull_image(self.get_update_custom_concepts_image_name_tag())
        self._docker_client.pull_image(self.get_rebuild_concept_hierarchy_image_name_tag())

    def _delete_base_indexes(self):
        self._run_container(image=self.get_delete_base_indexes_image_name_tag(),
                            name='omopcdm-delete-base-indexes')

    def _delete_constraints(self):
        self._run_container(image=self.get_delete_constraints_image_name_tag(),
                            name='omopcdm-delete-constraints')

    def _add_constraints(self):
        self._run_container(image=self.get_add_constraints_image_name_tag(),
                            name='omopcdm-add-constraints')

    def _add_base_indexes(self):
        self._run_container(image=self.get_add_base_indexes_image_name_tag(),
                            name='omopcdm-add-base-indexes')

    def _update_vocabulary(self):
        self._run_container(image=self.get_update_vocabulary_image_name_tag(),
                            name='omopcdm-update-vocabulary')

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

    def get_delete_base_indexes_image_name_tag(self):
        return self._docker_client.get_image_name_tag('postgres', 'omopcdm-delete-base-indexes-2.0.0')

    def get_add_base_indexes_image_name_tag(self):
        return self._docker_client.get_image_name_tag('postgres', 'omopcdm-add-base-indexes-2.0.0')

    def get_delete_constraints_image_name_tag(self):
        return self._docker_client.get_image_name_tag('postgres', 'omopcdm-delete-constraints-2.0.0')

    def get_add_constraints_image_name_tag(self):
        return self._docker_client.get_image_name_tag('postgres', 'omopcdm-add-constraints-2.0.0')

    def get_update_vocabulary_image_name_tag(self):
        return self._docker_client.get_image_name_tag('postgres', 'omopcdm-update-vocabulary-2.0.0')

    def get_update_custom_concepts_image_name_tag(self):
        return self._docker_client.get_image_name_tag('omopcdm-update-custom-concepts', 'latest')

    def get_rebuild_concept_hierarchy_image_name_tag(self):
        return self._docker_client.get_image_name_tag('postgres', 'results-rebuild-concept-hierarchy-2.0.2')

    def get_network_name(self):
        return self._docker_client.get_network_name()