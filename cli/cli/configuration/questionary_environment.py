from cli.globals import Globals
from cli.configuration.question import Question
from cli.configuration.config_server_environment import Environment
from cli.therapeutic_area.therapeutic_area import TherapeuticArea

class QuestionaryEnvironment(Environment):

    def __init__(self, therapeutic_area:TherapeuticArea, current_directory:str, is_windows:bool, offline_mode:bool) -> None:
        super().__init__()
        self.therapeutic_area = therapeutic_area
        self.current_directory = current_directory
        self.is_windows = is_windows
        self.offline_mode = offline_mode

    def get_configuration(self, key:str) -> str:
        question:Question = Globals.get_question(key)
        if not question:
            return None
        return question.ask(self.therapeutic_area, self.current_directory, self.is_windows, self.offline_mode)