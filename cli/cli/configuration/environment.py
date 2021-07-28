from cli.globals import Globals
from cli.registry.registry import Registry


class Environment:

    configuration_key_question_map = {
        'feder8.local.host.name': 'Enter the FQDN(Fully Qualified Domain Name eg. www.example.com) or public IP address(eg. 125.24.44.18) of the host machine. Use localhost to for testing?',
        'feder8.central.service.image-repo-username': 'Enter email address used to login to FEDER8_PORTAL_URL?',
        'feder8.central.service.image-repo-key': 'Surf to FEDER8_REGISTRY_URL and login using the button "LOGIN VIA OIDC PROVIDER". Then click your account name on the top right corner of the screen and click "User Profile". Copy the CLI secret by clicking the copy symbol next to the text field. Enter the CLI Secret?'
    }

    def get_configuration(self, key:str) -> str:
        pass