from typing import List
from cli.registry.registry import Registry

class TherapeuticArea:
    def __init__(self, name:str, light_theme:str, dark_theme:str, portal_url:str, catalogue_url:str, distributed_analytics_url:str, cas_url:str, registry:Registry, organizations: List[str]) -> None:
        self.name:str = name
        self.portal_url:str = portal_url
        self.catalogue_url:str = catalogue_url
        self.distributed_analytics_url:str = distributed_analytics_url
        self.cas_url:str = cas_url
        self.registry:Registry = registry
        self.light_theme:str = light_theme
        self.dark_theme:str = dark_theme
        self.organizations:List[str] = organizations