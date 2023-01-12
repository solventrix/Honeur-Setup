import logging

import docker

from cli.configuration.DockerClientFacade import DockerClientFacade
from cli.configuration.ImageLookup import get_postgres_omopcdm_initialize_schema_image_name_tag, \
    get_postgres_omopcdm_add_base_primary_keys_image_name_tag, get_postgres_omopcdm_add_base_indexes_image_name_tag, \
    get_postgres_results_initialize_schema_image_name_tag, get_postgres_webapi_add_source_image_name_tag
from cli.configuration.cdm_version import CdmVersion
from cli.globals import Globals
from cli.therapeutic_area.therapeutic_area import TherapeuticArea

SHARED_VOLUME = 'shared'


class AddCdmSchema54Pipeline:

    def __init__(self, docker_client: DockerClientFacade,
                 therapeutic_area_info: TherapeuticArea,
                 feder8_admin_username: str,
                 cdm_schema: str, vocabulary_schema: str, results_schema: str) -> None:
        self._docker_client = docker_client
        self._therapeutic_area_info = therapeutic_area_info
        self._feder8_admin_username = feder8_admin_username
        self._results_schema = results_schema
        self._vocabulary_schema = vocabulary_schema
        self._cdm_schema = cdm_schema


    def execute(self):
        self.validate_postgres_running()

        self.initialize_omop_cdm_schema()
        logging.info('Finished initializing schema')

        self.add_base_primary_keys()

        self.add_base_indexes()

        self.initialize_results_schema()

        source_name = self.add_webapi_source()

        self.restart_webapi()

        print(f'Please grant role [{source_name}] to all applicable users in user management.')

    def add_webapi_source(self) -> str:
        webapi_add_source_image_name_tag = get_postgres_webapi_add_source_image_name_tag(
            self._therapeutic_area_info)
        self._docker_client.pull_image(webapi_add_source_image_name_tag)

        source_name = self._therapeutic_area_info.name.upper() + " OMOP CDM v5.4"
        environment_variables = {
            'CDMOMOP_CDM_VERSION': '5.4',
            'DB_HOST': 'postgres',
            'DB_CDM_SCHEMA': self._cdm_schema,
            'DB_VOCABULARY_SCHEMA': self._vocabulary_schema,
            'DB_RESULTS_SCHEMA': self._results_schema,
            'FEDER8_SOURCE_NAME': source_name,
            'FEDER8_DATABASE_HOST': 'postgres',
        }

        logging.info('Adding WebAPI source...')
        self._docker_client.run_container(
            image=webapi_add_source_image_name_tag,
            name='postgres_webapi_add_source',
            remove=True,
            environment=environment_variables,
            network=Globals.FEDER8_NET,
            volumes={
                SHARED_VOLUME: {
                    'bind': '/var/lib/shared'
                }
            },
            detach=False
        )
        logging.info('Finished adding WebAPI source')
        return source_name

    def initialize_results_schema(self):
        results_initialize_schema_image_name_tag = get_postgres_results_initialize_schema_image_name_tag(
            self._therapeutic_area_info)
        self._docker_client.pull_image(results_initialize_schema_image_name_tag)

        environment_variables = {
            'CDMOMOP_CDM_VERSION': '5.4',
            'DB_HOST': 'postgres',
            'DB_RESULTS_SCHEMA': self._results_schema,
            'FEDER8_ADMIN_USERNAME': self._feder8_admin_username,
        }

        logging.info('Initializing results schema...')
        self._docker_client.run_container(
            image=results_initialize_schema_image_name_tag,
            name='postgres_results_initialize_schema',
            remove=True,
            environment=environment_variables,
            network=Globals.FEDER8_NET,
            volumes={
                SHARED_VOLUME: {
                    'bind': '/var/lib/shared'
                }
            },
            detach=False,
            show_logs=True
        )
        logging.info('Finished initializing results schema')

    def add_base_indexes(self):
        add_base_indexes_image_name_tag = get_postgres_omopcdm_add_base_indexes_image_name_tag(
            self._therapeutic_area_info, CdmVersion.v5_4)
        self._docker_client.pull_image(add_base_indexes_image_name_tag)

        environment_variables = {
            'CDMOMOP_CDM_VERSION': '5.4',
            'DB_HOST': 'postgres',
            'DB_OMOPCDM_SCHEMA': self._cdm_schema,
        }

        logging.info('Adding base base indexes...')
        self._docker_client.run_container(
            image=add_base_indexes_image_name_tag,
            name='postgres_add_base_indexes',
            remove=True,
            environment=environment_variables,
            network=Globals.FEDER8_NET,
            volumes={
                SHARED_VOLUME: {
                    'bind': '/var/lib/shared'
                }
            },
            detach=False,
            show_logs=True
        )
        logging.info('Finished adding base indexes')

    def add_base_primary_keys(self):
        add_base_primary_keys_image_name_tag = get_postgres_omopcdm_add_base_primary_keys_image_name_tag(
            self._therapeutic_area_info, CdmVersion.v5_4)
        self._docker_client.pull_image(add_base_primary_keys_image_name_tag)

        environment_variables = {
            'CDMOMOP_CDM_VERSION': '5.4',
            'DB_HOST': 'postgres',
            'DB_OMOPCDM_SCHEMA': self._cdm_schema,
        }

        logging.info('Adding base primary keys...')
        self._docker_client.run_container(
            image=add_base_primary_keys_image_name_tag,
            name='postgres_add_base_primary_keys',
            remove=True,
            environment=environment_variables,
            network=Globals.FEDER8_NET,
            volumes={
                SHARED_VOLUME: {
                    'bind': '/var/lib/shared'
                }
            },
            detach=False,
            show_logs=True
        )
        logging.info('Finished adding base primary keys')

    def initialize_omop_cdm_schema(self):
        init_schema_image_name_tag = get_postgres_omopcdm_initialize_schema_image_name_tag(self._therapeutic_area_info,
                                                                                           CdmVersion.v5_4)
        self._docker_client.pull_image(init_schema_image_name_tag)

        environment_variables = {
            'CDMOMOP_CDM_VERSION': '5.4',
            'DB_HOST': 'postgres',
            'DB_OMOPCDM_SCHEMA': self._cdm_schema,
            'FEDER8_ADMIN_USERNAME': self._feder8_admin_username,
        }

        logging.info('Initializing OMOP CDM v5.4 schema...')
        try:
            self._docker_client.run_container(
                image=init_schema_image_name_tag,
                name='postgres_initialize_omopcdm_schema',
                remove=True,
                environment=environment_variables,
                network=Globals.FEDER8_NET,
                volumes={
                    SHARED_VOLUME: {
                        'bind': '/var/lib/shared'
                    }
                },
                detach=False,
                show_logs=True
            )
        except docker.errors.ContainerError as e:
            logging.error(f'Error while creating schema {self._cdm_schema}. Schema might already exist. Exiting.')
            raise RuntimeError(e)

    def validate_postgres_running(self):
        logging.info('Checking if existing database is reachable...')
        if not self._docker_client.validate_running('postgres'):
            logging.error('Database not running...')
            raise RuntimeError

    def restart_webapi(self):
        self._docker_client.restart_container('webapi')

