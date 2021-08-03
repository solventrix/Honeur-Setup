from cli.therapeutic_area.therapeutic_area import TherapeuticArea
import strgen

class Question:

    def __init__(self, text:str, default:str) -> None:
        self.text = text
        self.default = default

    def ask(self, therapeutic_area:TherapeuticArea, current_directory:str, is_windows:bool) -> str:
        question:str = self.text
        question = question.replace('FEDER8_PORTAL_URL', therapeutic_area.portal_url)
        question = question.replace('FEDER8_REGISTRY_URL', therapeutic_area.registry.registry_url)
        question = question.replace('FEDER8_THERAPEUTIC_AREA', therapeutic_area.name)
        question = question.replace('FEDER8_CURRENT_DIRECTORY', current_directory)
        if is_windows:
            question = question.replace('FEDER8_DIRECTORY_SEPARATOR', '\\')
        else:
            question = question.replace('FEDER8_DIRECTORY_SEPARATOR', '/')

        question_default = self.default
        if question_default is not None:
            question_default = question_default.replace('FEDER8_PORTAL_URL', therapeutic_area.portal_url)
            question_default = question_default.replace('FEDER8_REGISTRY_URL', therapeutic_area.registry.registry_url)
            question_default = question_default.replace('FEDER8_THERAPEUTIC_AREA', therapeutic_area.name)
            question_default = question_default.replace('FEDER8_RANDOM_PASSWORD', strgen.StringGenerator(r"[\w]{16}").render())
            question_default = question_default.replace('FEDER8_CURRENT_DIRECTORY', current_directory)
            if is_windows:
                question_default = question_default.replace('FEDER8_DIRECTORY_SEPARATOR', '\\')
            else:
                question_default = question_default.replace('FEDER8_DIRECTORY_SEPARATOR', '/')
        return self.ask_question(question, question_default)

    def ask_question(self, question:str, default:str) -> str:
        pass
