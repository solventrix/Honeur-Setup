from cli.configuration.multiple_choice_question import MultipleChoiceQuestion
from cli.configuration.single_choice_question import SingleChoiceQuestion
from cli.configuration.question import Question
from cli.registry.registry import Registry
from cli.therapeutic_area.therapeutic_area import TherapeuticArea
from typing import Dict, List


class Globals:
    therapeutic_areas:Dict[str, TherapeuticArea] = {
        "HONEUR": TherapeuticArea('honeur', '#0794e0', '#002562', 'portal-dev.honeur.org', 'catalogue-dev.honeur.org', 'distributed-analytics-dev.honeur.org', 'cas-dev.honeur.org', Registry('harbor.honeur.org', 'honeur'), ['Jannsen', 'TestOrg1', 'TestOrg2', 'TestOrg3']),
        "PHederation": TherapeuticArea('phederation', '#3590d5', '#0741ad', 'portal-dev.phederation.org', 'catalogue-dev.phederation.org', 'distributed-analytics-dev.phederation.org', 'cas-dev.phederation.org', Registry('harbor.phederation.org', 'phederation'), ['Jannsen', 'TestOrg1', 'TestOrg2', 'TestOrg3']),
        "Esfurn": TherapeuticArea('esfurn', '#668772', '#44594c', 'portal-dev.esfurn.org', 'catalogue-dev.esfurn.org', 'distributed-analytics-dev.esfurn.org', 'cas-dev.esfurn.org', Registry('harbor.esfurn.org', 'esfurn'), ['Jannsen', 'TestOrg1', 'TestOrg2', 'TestOrg3']),
        "Athena": TherapeuticArea('athena', '#0794e0', '#002562', 'portal-dev.athenafederation.org', 'catalogue-dev.athenafederation.org', 'distributed-analytics-dev.athenafederation.org', 'cas-dev.athenafederation.org', Registry('harbor.athenafederation.org', 'athena'), ['Jannsen', 'TestOrg1', 'TestOrg2', 'TestOrg3'])
    }

    all_questions:Dict[str,Question] = {
        'feder8.local.host.name': SingleChoiceQuestion('Enter the FQDN(Fully Qualified Domain Name eg. www.example.com) or public IP address(eg. 125.24.44.18) of the host machine. Use localhost only for testing?', ''),
        'feder8.central.service.image-repo-username': SingleChoiceQuestion('Enter email address used to login to FEDER8_PORTAL_URL?', ''),
        'feder8.central.service.image-repo-key': SingleChoiceQuestion('Surf to FEDER8_REGISTRY_URL and login using the button "LOGIN VIA OIDC PROVIDER". Then click your account name on the top right corner of the screen and click "User Profile". Copy the CLI secret by clicking the copy symbol next to the text field. Enter the CLI Secret?', ''),
        'feder8.local.datasource.password': SingleChoiceQuestion('Enter password for FEDER8_THERAPEUTIC_AREA database user?', 'FEDER8_RANDOM_PASSWORD'),
        'feder8.local.datasource.admin-password': SingleChoiceQuestion('Enter password for FEDER8_THERAPEUTIC_AREA_admin database user?', 'FEDER8_RANDOM_PASSWORD'),
        'feder8.local.security.security-method': MultipleChoiceQuestion('Enter the security method to use?', ['None', 'JDBC', 'LDAP']),
        'feder8.local.security.ldap-url': SingleChoiceQuestion('Enter LDAP URL (e.g. ldap://ldap.forumsys.com:389)?', ''),
        'feder8.local.security.ldap-dn': SingleChoiceQuestion('Enter LDAP DN (e.g. uid=\{0\},dc=example,dc=com)?', ''),
        'feder8.local.security.ldap-base-dn': SingleChoiceQuestion('Enter LDAP Base DN (e.g. dc=example,dc=com)?', ''),
        'feder8.local.security.ldap-system-username': SingleChoiceQuestion('Enter LDAP System username?', ''),
        'feder8.local.security.ldap-system-password': SingleChoiceQuestion('Enter LDAP System password?', ''),
        'feder8.local.host.zeppelin-log-directory': SingleChoiceQuestion('Enter the directory where the Zeppelin logs will be kept on the host machine?', 'FEDER8_CURRENT_DIRECTORYFEDER8_DIRECTORY_SEPARATORzeppelinFEDER8_DIRECTORY_SEPARATORlogs'),
        'feder8.local.host.zeppelin-notebook-directory': SingleChoiceQuestion('Enter the directory where the Zeppelin notebooks will be kept on the host machine?', 'FEDER8_CURRENT_DIRECTORYFEDER8_DIRECTORY_SEPARATORzeppelinFEDER8_DIRECTORY_SEPARATORnotebook'),
        'feder8.local.host.feder8-studio-directory': SingleChoiceQuestion('Enter the directory where Feder8 Studio files will be kept on the host machine?', 'FEDER8_CURRENT_DIRECTORYFEDER8_DIRECTORY_SEPARATORFEDER8_THERAPEUTIC_AREA-studio'),
        'feder8.local.host.docker-cert-directory': SingleChoiceQuestion('Enter the folder containing the certificates?', 'FEDER8_CURRENT_DIRECTORYFEDER8_DIRECTORY_SEPARATORcertificatesFEDER8_DIRECTORY_SEPARATORfeder8-client-certificates'),
        'feder8.local.security.user-mgmt-username': SingleChoiceQuestion('Enter the administrator username?', 'admin'),
        'feder8.local.security.user-mgmt-password': SingleChoiceQuestion('Enter the administrator password?', 'admin')
    }