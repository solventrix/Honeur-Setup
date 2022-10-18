from cli.globals import Globals
from cli.therapeutic_area.therapeutic_area import TherapeuticArea
from cli.configuration.questionary_environment import QuestionaryEnvironment
from cli.configuration.config_server_environment import ConfigurationServerEnvironment
from cli.configuration.DatabaseConnectionDetails import DatabaseConnectionDetails


class ConfigurationController:

    def __init__(self, therapeutic_area:str, current_directory:str, is_windows:bool, offline_mode:bool) -> None:
        self.therapeutic_area:TherapeuticArea = Globals.therapeutic_areas[therapeutic_area]
        self.question_environment = QuestionaryEnvironment(self.therapeutic_area, current_directory, is_windows, offline_mode)
        self.config_server_environment = ConfigurationServerEnvironment(self.therapeutic_area)

    def get_configuration(self, key:str) -> str:
        response = self.config_server_environment.get_configuration(key)
        if response == '':
            response = self.ask(key)
        return response

    def ask(self, key:str):
        return self.question_environment.get_configuration(key)

    def get_optional_configuration(self, key:str) -> str:
        response = self.config_server_environment.get_configuration(key)
        if response == '':
            return None
        return response

    def get_image_repo_credentials(self):
        email = self.get_configuration('feder8.central.service.image-repo-username')
        cli_key = self.get_configuration('feder8.central.service.image-repo-key')
        return email, cli_key

    def get_database_connection_details(self):
        return DatabaseConnectionDetails(
            db_host = 'postgres',
            db_port = '5432',
            db_name='OHDSI',
            db_username=self.get_configuration('feder8.local.datasource.admin-username'),
            db_password=self.get_configuration('feder8.local.datasource.admin-password'),
            db_schema=self.get_configuration('feder8.local.datasource.vocabulary-schema')
        )
