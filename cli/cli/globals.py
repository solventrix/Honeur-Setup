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
