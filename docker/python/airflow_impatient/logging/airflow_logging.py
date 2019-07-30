from airflow.config_templates.airflow_local_settings import DEFAULT_LOGGING_CONFIG

AIRFLOW_LOGGING_CONFIG = DEFAULT_LOGGING_CONFIG.copy()
AIRFLOW_LOGGING_CONFIG['handlers']['task']['class'] = 'airflow_impatient.logging.file_task_handler.FileTaskHandler'