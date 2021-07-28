from cli.registry.registry import Registry

class TherapeuticArea:
    def __init__(self, name:str, portal_url:str, catalogue_url:str, cas_url:str, registry:Registry) -> None:
        self.name:str = name
        self.portal_url:str = portal_url
        self.catalogue_url:str = catalogue_url
        self.cas_url:str = cas_url
        self.registry:Registry = registry