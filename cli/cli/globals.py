from cli.configuration.multiple_choice_question import MultipleChoiceQuestion
from cli.configuration.single_choice_question import SingleChoiceQuestion
from cli.configuration.question import Question
from cli.configuration.cdm_version import CdmVersion
from cli.registry.registry import Registry
from cli.therapeutic_area.therapeutic_area import TherapeuticArea
from typing import Dict


class Globals:

    FEDER8_NET = "feder8-net"
    DISEASE_EXPLORER = "diseaseExplorer"

    @staticmethod
    def get_environment():
        return "UAT"

    therapeutic_areas:Dict[str, TherapeuticArea] = {
        "HONEUR": TherapeuticArea('honeur', '#0794e0', '#002562', 'portal-uat.honeur.org', 'catalogue-uat.honeur.org', 'distributed-analytics-uat.honeur.org', 'cas-uat.honeur.org', Registry('harbor-uat.honeur.org', 'honeur'), ['CCL','CHU Dijon','CHU Lille','CHU Montpellier','CLLEAR','DOS','EMMOS','IUCT','iOMEDICO','Janssen','OIS','Oncotyrol','RMG', 'UHL','EY', 'ZOL', 'HOPE','Security Scan', 'TestOrg1', 'TestOrg2', 'TestOrg3', 'TestOrg4', 'TestOrg5', 'TestOrg6']),
        "PHederation": TherapeuticArea('phederation', '#3590d5', '#0741ad', 'portal-uat.phederation.org', 'catalogue-uat.phederation.org', 'distributed-analytics-uat.phederation.org', 'cas-uat.phederation.org', Registry('harbor-uat.phederation.org', 'phederation'), ['Security Scan', 'Janssen', 'Actelion', 'PHederationTestOrg1', 'PHederationTestOrg2', 'PHederationTestOrg3', 'PHederationTestOrg4', 'PHederationTestOrg5', 'PHederationTestOrg6']),
        "Esfurn": TherapeuticArea('esfurn', '#668772', '#44594c', 'portal-uat.esfurn.org', 'catalogue-uat.esfurn.org', 'distributed-analytics-uat.esfurn.org', 'cas-uat.esfurn.org', Registry('harbor-uat.esfurn.org', 'esfurn'), ['DARM', 'Janssen', 'EsfurnTestOrg1', 'EsfurnTestOrg2', 'EsfurnTestOrg3', 'EsfurnTestOrg4', 'EsfurnTestOrg5', 'EsfurnTestOrg6']),
        "Athena": TherapeuticArea('athena', '#0794e0', '#002562', 'portal-uat.athenafederation.org', 'catalogue-uat.athenafederation.org', 'distributed-analytics-uat.athenafederation.org', 'cas-uat.athenafederation.org', Registry('harbor-uat.athenafederation.org', 'athena'), ['CHU Liege', 'Illumina', 'KU Leuven', 'UZ Leuven', 'AZ Groeninge', 'Imec', 'imec-1', 'imec-2', 'imec-3', 'edenceHealth', 'Janssen', 'AthenaTestOrg1', 'AthenaTestOrg2', 'AthenaTestOrg3', 'AthenaTestOrg4', 'AthenaTestOrg5', 'AthenaTestOrg6']),
        "Lupus": TherapeuticArea('lupus', '#0794e0', '#002562', 'portal-uat.lupusnet.org', 'catalogue-uat.lupusnet.org', 'distributed-analytics-uat.lupusnet.org', 'cas-uat.lupusnet.org', Registry('harbor-uat.lupusnet.org', 'lupus'), ['Gladel', 'Janssen', 'Registry 1', 'Registry 2', 'LupusnetTestOrg1', 'LupusnetTestOrg2', 'LupusnetTestOrg3', 'LupusnetTestOrg4', 'LupusnetTestOrg5', 'LupusnetTestOrg6'], cdm_version=CdmVersion.v5_4)
    }

    all_questions:Dict[str,Question] = {
        'feder8.local.host.name': SingleChoiceQuestion('Enter the FQDN(Fully Qualified Domain Name eg. www.example.com) or public IP address(eg. 125.24.44.18) of the host machine. Use localhost only for testing?', ''),
        'feder8.central.service.image-repo-username': SingleChoiceQuestion('Enter email address used to login to FEDER8_PORTAL_URL?', '', skip_in_offline_mode=True),
        'feder8.central.service.image-repo-key': SingleChoiceQuestion('Surf to FEDER8_REGISTRY_URL and login using the button "LOGIN VIA OIDC PROVIDER". Then click your account name on the top right corner of the screen and click "User Profile". Copy the CLI secret by clicking the copy symbol next to the text field. Enter the CLI Secret?', '', skip_in_offline_mode=True),
        'feder8.local.datasource.password': SingleChoiceQuestion('Enter password for FEDER8_THERAPEUTIC_AREA database user?', 'FEDER8_RANDOM_PASSWORD'),
        'feder8.local.datasource.admin-password': SingleChoiceQuestion('Enter password for FEDER8_THERAPEUTIC_AREA_admin database user?', 'FEDER8_RANDOM_PASSWORD'),
        'feder8.local.security.security-method': MultipleChoiceQuestion('Enter the security method to use?', ['None', 'JDBC', 'LDAP']),
        'feder8.local.security.ldap-url': SingleChoiceQuestion('Enter LDAP URL (e.g. ldap://ldap.forumsys.com:389)?', ''),
        'feder8.local.security.ldap-dn': SingleChoiceQuestion('Enter LDAP DN (e.g. uid={0})?', ''),
        'feder8.local.security.ldap-base-dn': SingleChoiceQuestion('Enter LDAP Base DN (e.g. dc=example,dc=com)?', ''),
        'feder8.local.security.ldap-system-username': SingleChoiceQuestion('Enter LDAP System username (e.g. cn=read-only-admin,dc=example,dc=com)?', ''),
        'feder8.local.security.ldap-system-password': SingleChoiceQuestion('Enter LDAP System password?', ''),
        'feder8.local.host.zeppelin-log-directory': SingleChoiceQuestion('Enter the directory where the Zeppelin logs will be kept on the host machine?', 'FEDER8_CURRENT_DIRECTORYFEDER8_DIRECTORY_SEPARATORzeppelinFEDER8_DIRECTORY_SEPARATORlogs'),
        'feder8.local.host.zeppelin-notebook-directory': SingleChoiceQuestion('Enter the directory where the Zeppelin notebooks will be kept on the host machine?', 'FEDER8_CURRENT_DIRECTORYFEDER8_DIRECTORY_SEPARATORzeppelinFEDER8_DIRECTORY_SEPARATORnotebook'),
        'feder8.local.host.feder8-studio-directory': SingleChoiceQuestion('Enter the directory where Feder8 Studio files will be kept on the host machine?', 'FEDER8_CURRENT_DIRECTORYFEDER8_DIRECTORY_SEPARATORFEDER8_THERAPEUTIC_AREA-studio'),
        'feder8.local.host.docker-cert-directory': SingleChoiceQuestion('Enter the folder containing the certificates generated by the generate-docker-certificates.sh script?', 'FEDER8_CURRENT_DIRECTORYFEDER8_DIRECTORY_SEPARATORcertificatesFEDER8_DIRECTORY_SEPARATORfeder8-client-certificates'),
        'feder8.local.host.ssl-cert-directory': SingleChoiceQuestion('Enter the folder containing the certificates to enable HTTPS? This should be a folder containing public certificate "feder8.crt" and private key "feder8.key" generated by your Certificate Authority', 'FEDER8_CURRENT_DIRECTORYFEDER8_DIRECTORY_SEPARATORcertificatesFEDER8_DIRECTORY_SEPARATORssl'),
        'feder8.local.security.user-mgmt-username': SingleChoiceQuestion('Enter the administrator username?', 'admin'),
        'feder8.local.security.user-mgmt-password': SingleChoiceQuestion('Enter the administrator password?', 'admin'),
    }

    @staticmethod
    def get_question(key):
        return Globals.all_questions.get(key)
