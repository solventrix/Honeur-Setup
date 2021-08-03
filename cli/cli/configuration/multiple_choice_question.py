from typing import Any, Dict, List, Optional, Union
from cli.configuration.question import Question
import questionary
from questionary.prompts.common import Choice

class MultipleChoiceQuestion(Question):

    def __init__(self, text:str, choices:List[str]) -> None:
        super().__init__(text, None)
        self.choices:List[str] = choices

    def ask_question(self, question:str, default:str) -> str:
        return questionary.select(question, choices=self.choices, default=default).unsafe_ask()