from enum import Enum


class CdmVersion(Enum):
    v5_3_1 = '5.3.1'
    v5_4 = '5.4'

    @staticmethod
    def value_of(version_str: str):
        if version_str == CdmVersion.v5_3_1.value:
            return CdmVersion.v5_3_1
        elif version_str == CdmVersion.v5_4.value:
            return CdmVersion.v5_4
        else:
            return None

    def __str__(self):
        return str(self.value)
