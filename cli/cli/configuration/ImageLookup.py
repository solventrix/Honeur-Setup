import logging
from cli.globals import Globals


def get_all_feder8_local_image_name_tags(therapeutic_area_info):
    return [
        get_postgres_image_name_tag(therapeutic_area_info),
        get_config_server_image_name_tag(therapeutic_area_info),
        get_update_configuration_image_name_tag(therapeutic_area_info),
        get_local_portal_image_name_tag(therapeutic_area_info),
        get_user_mgmt_image_name_tag(therapeutic_area_info),
        get_atlas_image_name_tag(therapeutic_area_info),
        get_webapi_image_name_tag(therapeutic_area_info),
        get_zeppelin_image_name_tag(therapeutic_area_info),
        get_distributed_analytics_r_server_image_name_tag(therapeutic_area_info),
        get_distributed_analytics_remote_image_name_tag(therapeutic_area_info),
        get_feder8_studio_image_name_tag(therapeutic_area_info),
        get_vs_code_server_image_name_tag(therapeutic_area_info),
        get_r_studio_server_image_name_tag(therapeutic_area_info),
        get_shiny_server_image_name_tag(therapeutic_area_info),
        get_disease_explorer_image_name_tag(therapeutic_area_info),
        get_nginx_image_name_tag(therapeutic_area_info),
        get_vocabulary_update_image_name_tag(therapeutic_area_info),
        get_local_backup_image_name_tag(therapeutic_area_info),
        get_fix_default_privileges_image_name_tag(therapeutic_area_info)
    ]


def get_postgres_image_name_tag(therapeutic_area_info):
    cdm_version = therapeutic_area_info.cdm_version
    return get_image_name_tag(therapeutic_area_info, 'postgres', f'13-omopcdm-{cdm_version}-webapi-2.9.0-2.0.8')


def get_config_server_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'config-server', '2.0.2')


def get_update_configuration_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'config-server', 'update-configuration-2.0.1')


def get_local_portal_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'local-portal', '2.0.10')


def get_user_mgmt_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'user-mgmt', '2.0.5')


def get_atlas_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'atlas', '2.9.0-2.0.1')


def get_webapi_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'webapi', '2.9.0-2.0.3')


def get_zeppelin_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'zeppelin', '0.8.2-2.0.6')


def get_distributed_analytics_r_server_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'distributed-analytics', 'r-server-2.0.5')


def get_distributed_analytics_remote_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'distributed-analytics', 'remote-2.0.6')


def get_feder8_studio_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'feder8-studio', '2.0.13')


def get_vs_code_server_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'vs-code-server', '4.4.0')


def get_r_studio_server_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'r-studio-server', '4.2.0')


def get_shiny_server_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'shiny-server', '4.2.0')


def get_disease_explorer_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'disease-explorer', '0.3.1', restricted=True)


def get_feder8_studio_app_installer_image_name_tag(therapeutic_area_info, app_name):
    if app_name == Globals.RADIANT:
        return get_image_name_tag(therapeutic_area_info, 'install-radiant', '2.0.0')
    if app_name == Globals.DISEASE_EXPLORER:
        return get_image_name_tag(therapeutic_area_info, 'install-disease-explorer', '2.0.0')
    else:
        logging.warning(f"Unsupported application {app_name}")


def get_task_manager_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'task-manager', '2.0.4')


def get_nginx_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'nginx', '2.0.11')


def get_vocabulary_update_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'postgres', 'pipeline-vocabulary-update-2.0.2')


def get_local_backup_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'backup', '2.0.1')


def get_fix_default_privileges_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'postgres', 'fix-default-permissions-2.0.1')


def get_postgres_omopcdm_initialize_schema_image_name_tag(therapeutic_area_info, cdm_version):
    return get_image_name_tag(therapeutic_area_info, 'postgres-omopcdm-initialize-schema', str(cdm_version) + '-2.0.2')


def get_postgres_omopcdm_add_base_primary_keys_image_name_tag(therapeutic_area_info, cdm_version):
    return get_image_name_tag(therapeutic_area_info, 'postgres-omopcdm-add-base-primary-keys', str(cdm_version) + '-2.0.1')


def get_postgres_omopcdm_add_base_indexes_image_name_tag(therapeutic_area_info, cdm_version):
    return get_image_name_tag(therapeutic_area_info, 'postgres-omopcdm-add-base-indexes', str(cdm_version) + '-2.0.1')


def get_postgres_results_initialize_schema_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'postgres-results-initialize-schema', '2.0.3')


def get_postgres_webapi_add_source_image_name_tag(therapeutic_area_info):
    return get_image_name_tag(therapeutic_area_info, 'postgres-webapi-add-source', '2.0.1')


def get_alpine_image_name_tag():
    return 'alpine:3.15.0'


def get_postgres_9_6_image_name_tag():
    return 'postgres:9.6'


def get_postgres_13_image_name_tag():
    return 'postgres:13'


def get_tianon_postgres_upgrade_9_6_to_13_image_name_tag():
    return 'tianon/postgres-upgrade:9.6-to-13'


def get_image_name_tag(therapeutic_area_info, name, tag, restricted=False):
    registry = therapeutic_area_info.registry
    project = registry.project
    if restricted:
        project += "-restricted"
    image_name = '/'.join([registry.registry_url, project, name])
    return ':'.join([image_name, tag])

