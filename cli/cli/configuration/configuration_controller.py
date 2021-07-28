from cli.globals import Globals
from cli.therapeutic_area.therapeutic_area import TherapeuticArea
from cli.configuration.environment import Environment
from cli.configuration.questionary_environment import QuestionaryEnvironment
from cli.configuration.config_server_environment import ConfigurationServerEnvironment
from config.spring import ConfigClient


class ConfigurationController:

    def __init__(self, therapeutic_area:str) -> None:
        self.environment:Environment
        self.therapeutic_area:TherapeuticArea = Globals.therapeutic_areas[therapeutic_area]
        self.check_environment()

    def get_configuration(self, key:str) -> str:
        return self.environment.get_configuration(key)

    def check_environment(self):
        config_client = ConfigClient(
            address='http://root:s3cr3t@config-server:8080',
            branch='master',
            profile='default',
            app_name='feder8-config-honeur',
            url="{address}/{branch}/{profile}-{app_name}.yaml"
        )

        try:
            config_client.get_config()
            self.environment = ConfigurationServerEnvironment(config_client)
        except:
            self.environment = QuestionaryEnvironment(self.therapeutic_area)
