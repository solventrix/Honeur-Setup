from cli.registry.registry import Registry

class TherapeuticArea:
    def __init__(self, name:str, light_theme:str, dark_theme:str, portal_url:str, catalogue_url:str, distributed_analytics_url:str, cas_url:str, registry:Registry) -> None:
        self.name:str = name
        self.portal_url:str = portal_url
        self.catalogue_url:str = catalogue_url
        self.distributed_analytics_url:str = distributed_analytics_url
        self.cas_url:str = cas_url
        self.registry:Registry = registry
        self.light_theme = light_theme
        self.dark_theme = dark_theme