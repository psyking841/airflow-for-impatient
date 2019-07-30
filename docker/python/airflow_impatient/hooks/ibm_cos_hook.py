import logging

from airflow.exceptions import AirflowException
from airflow.hooks.base_hook import BaseHook

class IbmCosHook(BaseHook):
    """
    Interact with IBMCloud.
    """

    def __init__(self, ibm_cos_conn_id, verify=None):
        self.ibm_cos_conn_id = ibm_cos_conn_id
        self.verify = verify

    def get_cos_params(self):
        if self.ibm_cos_conn_id:
            try:
                connection_object = self.get_connection(self.ibm_cos_conn_id)
                extra_config = connection_object.extra_dejson
                cos_service_id = connection_object.login
                api_key = connection_object.password
                cos_service_name = connection_object.schema
                endpoint_url = connection_object.host

                return {"cos_service_id": cos_service_id,
                        "api_key": api_key,
                        "cos_service_name": cos_service_name,
                        "endpoint_url": endpoint_url}
            except AirflowException:
                # No connection found
                logging.error("No connection to IBM COS service found")
