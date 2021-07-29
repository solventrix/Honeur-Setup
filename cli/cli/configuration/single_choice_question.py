from cli.configuration.question import Question

import questionary

class SingleChoiceQuestion(Question):

    def ask_question(self, question:str) -> str:
        return questionary.text(question).ask()