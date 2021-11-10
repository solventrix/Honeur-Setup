from cli.globals import Globals
from cli.therapeutic_area.therapeutic_area import TherapeuticArea
from cli.configuration.questionary_environment import QuestionaryEnvironment
from cli.configuration.config_server_environment import ConfigurationServerEnvironment


class ConfigurationController:

    def __init__(self, therapeutic_area:str, current_directory:str, is_windows:bool) -> None:
        self.therapeutic_area:TherapeuticArea = Globals.therapeutic_areas[therapeutic_area]
        self.question_environment = QuestionaryEnvironment(self.therapeutic_area, current_directory, is_windows)
        self.config_server_environment = ConfigurationServerEnvironment(self.therapeutic_area)

    def get_configuration(self, key:str) -> str:
        response = self.config_server_environment.get_configuration(key)
        if response == '':
            response = self.question_environment.get_configuration(key)
        return response
