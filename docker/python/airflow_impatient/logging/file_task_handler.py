import os, threading, time
from kubernetes import config, client
from airflow.utils.log.file_task_handler import FileTaskHandler
from airflow.utils.log.logging_mixin import LoggingMixin

log = LoggingMixin().log

lock = threading.Lock() # Lock on the known_hosts dict

class FileTaskHandler(FileTaskHandler):
    """
    FileTaskHandler inherits the build-in FileTaskHandler, and is introduced to rename the hostname with ip address.
    This is because the KubeDNS cannot resolve the hostname, but ip address of pods.
    """
    def __init__(self, base_log_folder, filename_template):
        super(FileTaskHandler, self).__init__(base_log_folder, filename_template)
        # Only when running under kubernetes
        if ('KUBECONFIG' in os.environ) and os.environ['KUBECONFIG']:
            log.info("KUBECONFIG = %s", os.environ['KUBECONFIG'])
            #self.namespace = config.list_kube_config_contexts()[1]['context']['namespace']
            try:
                self.namespace = \
                    os.environ.get("KUBE_NAMESPACE", config.list_kube_config_contexts()[1]['context']['namespace'])
                log.info("Connect to namespace: %s", self.namespace)
            except IndexError:
                pass # Use default namespace
            except KeyError:
                pass # Use default namespace
            # Init kube client
            config.load_kube_config()
            self.kube_client = client.CoreV1Api()
            self.known_hosts = {}
            # Running a daemon in the background for updating the map periodically
            t = threading.Thread(target=self.get_known_hosts_map)
            t.setDaemon(True)
            t.start()

    def get_known_hosts_map(self, frequency=30):
        """
        This function is for massive lookup. The lookup is performed every coupld of seconds
        :param frequency: how frequent the lookup should be performed, in seconds
        :return:
        """
        while True:
            pod_list = self.kube_client.list_namespaced_pod(self.namespace)
            with lock:
                for item in pod_list.items:
                    if item.metadata.labels["tier"] == "worker":
                        self.known_hosts[item.metadata.name] = item.status.pod_ip
            time.sleep(frequency)

    def get_ip_for(self, hostname):
        """
        This function is for individual lookup. It returns the ip address looked up using kubernetes python library.
        :return: ip address of a hostname
        """
        pod_list = self.kube_client.list_namespaced_pod(self.namespace)
        for item in pod_list.items:
            if hostname == item.metadata.name:
                return item.status.pod_ip
        # Not found
        raise Exception("No ip found for host: ", hostname)

    def _read(self, ti, try_number, metadata=None):
        """
        Implement the logic to parse hostname to ip, in case master node cannot resolve the hostname, for example, in EC2 cluster and k8s
        :param ti: task object instance
        :param try_number: max number of retry
        :return:
        """
        # If this is not running in Kubernetes, then just run the super class' method:
        if ('KUBECONFIG' not in os.environ) or (not os.environ['KUBECONFIG']):
            return super(FileTaskHandler, self)._read(ti, try_number, metadata)

        # Look up dns for ip from hostname
        hostname = ti.hostname
        try:
            ti.hostname = self.known_hosts[hostname]
        except KeyError as kerr:
            log.warn("Key error: {}".format(kerr))
            log.info("Lookup {} from kubectl")
            try:
                ti.hostname = self.get_ip_for(hostname)
                log.info("Ip of host {} is {}".format(hostname, ti.hostname))
                # Update the map
                with lock:
                    self.known_hosts[hostname] = ti.hostname
            except RuntimeError as rerr:
                log.warn(rerr)
        return super(FileTaskHandler, self)._read(ti, try_number, metadata)
