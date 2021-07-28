from cli.configuration.config_server_environment import Environment
from cli.therapeutic_area.therapeutic_area import TherapeuticArea
import questionary

class QuestionaryEnvironment(Environment):

    def __init__(self, therapeutic_area:TherapeuticArea) -> None:
        super().__init__()
        self.therapeutic_area = therapeutic_area

    def get_configuration(self, key:str) -> str:
        question:str = Environment.configuration_key_question_map[key]
        question = question.replace('FEDER8_PORTAL_URL', self.therapeutic_area.portal_url)
        question = question.replace('FEDER8_REGISTRY_URL', self.therapeutic_area.registry.registry_url)
        return questionary.text(question).ask()