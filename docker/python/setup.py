from setuptools import setup

setup(name='airflow_impatient',
      version='0.0.2',
      description='Customized logging handlers, hooks and operators for Airflow to be run in K8s',
      url='https://pypi.org/project/airflow-impatient/',
      author='Shengyi Pan',
      author_email='shengyi.pan@ibm.com',
      license='Apache',
      package_data={'airflow_impatient': ['LICENSE']},
      packages=['airflow_impatient.logging', 'airflow_impatient.hooks', 'airflow_impatient.operators'],
      zip_safe=False)