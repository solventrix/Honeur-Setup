from cli.globals import Globals
from cli.configuration.question import Question
from cli.configuration.config_server_environment import Environment
from cli.therapeutic_area.therapeutic_area import TherapeuticArea

class QuestionaryEnvironment(Environment):

    def __init__(self, therapeutic_area:TherapeuticArea) -> None:
        super().__init__()
        self.therapeutic_area = therapeutic_area

    def get_configuration(self, key:str) -> str:
        question:Question = Globals.all_questions[key]
        return question.ask(self.therapeutic_area)