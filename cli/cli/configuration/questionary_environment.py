from cli.globals import Globals
from cli.configuration.question import Question
from cli.configuration.config_server_environment import Environment
from cli.therapeutic_area.therapeutic_area import TherapeuticArea

class QuestionaryEnvironment(Environment):

    def __init__(self, therapeutic_area:TherapeuticArea, current_directory:str, is_windows:bool) -> None:
        super().__init__()
        self.therapeutic_area = therapeutic_area
        self.current_directory = current_directory
        self.is_windows = is_windows

    def get_configuration(self, key:str) -> str:
        question:Question = Globals.all_questions[key]
        return question.ask(self.therapeutic_area, self.current_directory, self.is_windows)