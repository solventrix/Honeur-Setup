import logging
import pandas as pd
from pyfeder8.config.ConfigurationClient import ConfigurationClient
from pyfeder8.TokenContextProvider import TokenContextProvider
from pyfeder8 import ScriptUuidFinder
from pyfeder8.catalogue.CatalogueClient import CatalogueClient

# Set log level to DEBUG
logging.basicConfig(level=logging.INFO)

# Get local configuration
configuration = ConfigurationClient(config_server="http://config-server:8080/config-server", config_name="feder8-config-honeur").get_configuration()
token_context = TokenContextProvider(configuration).get_token_context()
script_version_uuid = ScriptUuidFinder.find_script_uuid_in_env()
logging.info("Script UUID: {}".format(script_version_uuid))

# Create result data
data = [{'a': 1, 'b': 2, 'c': 3}, {'a': 10, 'b': 20, 'c': 30}]
df = pd.DataFrame(data)

# Share result with central platform
catalogue_client = CatalogueClient(configuration)
result_uuid = catalogue_client.save_dataframe_as_csv_script_result(script_version_uuid, df, filename='test_df_to_csv.csv', token_context=token_context)
logging.info("Result successfully saved!  UUID {}".format(result_uuid))
