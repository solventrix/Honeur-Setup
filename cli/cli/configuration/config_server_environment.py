from config.spring import ConfigClient

from cli.configuration.environment import Environment


class ConfigurationServerEnvironment(Environment):

    def __init__(self, config_client:ConfigClient) -> None:
        super().__init__()
        self.config_client = config_client

    def get_configuration(self, key:str) -> str:
        return self.config_client.get_attribute(key)