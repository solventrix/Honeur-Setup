from cli.therapeutic_area.therapeutic_area import TherapeuticArea


class Question:

    def __init__(self, text:str) -> None:
        self.text = text

    def ask(self, therapeutic_area:TherapeuticArea) -> str:
        question:str = self.text
        question = question.replace('FEDER8_PORTAL_URL', therapeutic_area.portal_url)
        question = question.replace('FEDER8_REGISTRY_URL', therapeutic_area.registry.registry_url)
        question = question.replace('FEDER8_THERAPEUTIC_AREA', therapeutic_area.name)
        return self.ask_question(question)

    def ask_question(self, question:str) -> str:
        pass
