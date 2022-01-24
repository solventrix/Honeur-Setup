import logging
from unittest import TestCase

from cli.configuration.DockerClientFacade import DockerClientFacade
from cli.configuration.DatabaseConnectionDetails import DatabaseConnectionDetails
from cli.globals import Globals
from cli.pipeline.CustomConceptsUpdatePipeline import CustomConceptsUpdatePipeline
from cli.therapeutic_area.therapeutic_area import TherapeuticArea

logging.basicConfig(level=logging.INFO)

class TestCustomConceptsUpdatePipeline(TestCase):

    def setUp(self):
        self.therapeutic_area_info = Globals.therapeutic_areas["HONEUR"]
        self.docker_client = DockerClientFacade(
            therapeutic_area_info,
            "<email>",
            "<cli_secret>")
        self.db_conn_details = DatabaseConnectionDetails(
            db_host='localhost',
            db_port='5444',
            db_name='OHDSI',
            db_username="honeur_admin",
            db_password="honeur_admin",
            db_schema="omopcdm")


    def test_custom_concepts_update_pipeline(self):
        pipeline = CustomConceptsUpdatePipeline(docker_client=docker_client, db_connection_details=db_conn_details)
        pipeline.execute()

