from cli.therapeutic_area.therapeutic_area import TherapeuticArea
from config.spring import ConfigClient

from cli.configuration.environment import Environment


class ConfigurationServerEnvironment(Environment):

    def __init__(self, therapeutic_area:TherapeuticArea) -> None:
        super().__init__()
        self.config_client = ConfigClient(
            address='http://root:s3cr3t@config-server:8080/config-server',
            branch='master',
            profile='default',
            app_name='feder8-config-' + therapeutic_area.name
        )

    def get_configuration(self, key:str) -> str:
        try:
            self.config_client.get_config()
            return self.config_client.get_attribute(key)
        except:
            return ''