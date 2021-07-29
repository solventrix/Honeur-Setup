from typing import List
from cli.configuration.question import Question
import questionary

class MultipleChoiceQuestion(Question):

    def __init__(self, text:str, choices:List[str]) -> None:
        super().__init__(text)
        self.choices:List[str] = choices

    def ask_question(self, question:str) -> str:
        return questionary.select(question, choices=self.choices).ask()