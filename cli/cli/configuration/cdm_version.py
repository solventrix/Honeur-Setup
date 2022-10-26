from enum import Enum


class CdmVersion(Enum):
    v5_3_1 = '5.3.1'
    v5_4 = '5.4'

    def __str__(self):
        return str(self.value)
