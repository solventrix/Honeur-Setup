from cli.configuration.multiple_choice_question import MultipleChoiceQuestion
from cli.configuration.single_choice_question import SingleChoiceQuestion
from cli.configuration.question import Question
from cli.registry.registry import Registry
from cli.therapeutic_area.therapeutic_area import TherapeuticArea
from typing import Dict


class Globals:
    therapeutic_areas:Dict[str, TherapeuticArea] = {
        "HONEUR": TherapeuticArea('honeur', '#0794e0', '#002562', 'portal.honeur.org', 'catalogue.honeur.org', 'cas.honeur.org', Registry('harbor.honeur.org', 'honeur')),
        "PHederation": TherapeuticArea('phederation', '#3590d5', '#0741ad', 'portal.phederation.org', 'catalogue.phederation.org', 'cas.phederation.org', Registry('harbor.phederation.org', 'phederation')),
        "Esfurn": TherapeuticArea('esfurn', '#668772', '#44594c', 'portal.esfurn.org', 'catalogue.esfurn.org', 'cas.esfurn.org', Registry('harbor.esfurn.org', 'esfurn')),
        "Athena": TherapeuticArea('athena', '#0794e0', '#002562', 'portal.athenafederation.org', 'catalogue.athenafederation.org', 'cas.athenafederation.org', Registry('harbor.athenafederation.org', 'athena'))
    }

    all_questions:Dict[str,Question] = {
        'feder8.local.host.name': SingleChoiceQuestion('Enter the FQDN(Fully Qualified Domain Name eg. www.example.com) or public IP address(eg. 125.24.44.18) of the host machine. Use localhost to for testing?'),
        'feder8.central.service.image-repo-username': SingleChoiceQuestion('Enter email address used to login to FEDER8_PORTAL_URL?'),
        'feder8.central.service.image-repo-key': SingleChoiceQuestion('Surf to FEDER8_REGISTRY_URL and login using the button "LOGIN VIA OIDC PROVIDER". Then click your account name on the top right corner of the screen and click "User Profile". Copy the CLI secret by clicking the copy symbol next to the text field. Enter the CLI Secret?'),
        'feder8.local.datasource.password': SingleChoiceQuestion('Enter password for FEDER8_THERAPEUTIC_AREA database user?'),
        'feder8.local.datasource.admin-password': SingleChoiceQuestion('Enter password for FEDER8_THERAPEUTIC_AREA_admin database user?'),
        'feder8.local.security.security-method': MultipleChoiceQuestion('Enter the security method to use?', ['None', 'JDBC', 'LDAP']),
        'feder8.local.security.ldap-url': SingleChoiceQuestion('Enter LDAP URL (e.g. ldap://ldap.forumsys.com:389)?'),
        'feder8.local.security.ldap-dn': SingleChoiceQuestion('Enter LDAP DN (e.g. uid=\{0\},dc=example,dc=com)?'),
        'feder8.local.security.ldap-base-dn': SingleChoiceQuestion('Enter LDAP Base DN (e.g. dc=example,dc=com)?'),
        'feder8.local.security.ldap-system-username': SingleChoiceQuestion('Enter LDAP System username?'),
        'feder8.local.security.ldap-system-password': SingleChoiceQuestion('Enter LDAP System password?'),
        'feder8.local.host.log-directory': SingleChoiceQuestion('Enter the directory where the Zeppelin logs will kept on the host machine?'),
        'feder8.local.host.notebook-directory': SingleChoiceQuestion('Enter the directory where the Zeppelin notebooks will kept on the host machine?'),
        'feder8.local.host.data-directory': SingleChoiceQuestion('Enter the directory where Zeppelin will save the prepared data?'),
    }