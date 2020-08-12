from datetime import datetime, timedelta
from airflow import DAG
from airflow.contrib.operators.kubernetes_pod_operator import KubernetesPodOperator

default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "start_date": datetime(2015, 6, 1),
    "email": ["airflow@airflow.com"],
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

company_onboarding = DAG('kube-operator',
                         default_args=default_args,
                         schedule_interval=timedelta(days=1))
with company_onboarding:
    pod_task_xcom = GKEStartPodOperator(
                        task_id="pod_task_xcom",
                        project_id="amaforge-scry",
                        location="us-central1-b",
                        cluster_name="scry-2",
                        do_xcom_push=True,
                        namespace="default",
                        image="alpine",
                        cmds=["sh", "-c", 'mkdir -p /airflow/xcom/;echo \'[1,2,3,4]\' > /airflow/xcom/return.json'],
                        name="test-pod-xcom",
                    )

    pod_task_xcom_result = BashOperator(
                              bash_command="echo \"{{ task_instance.xcom_pull('pod_task_xcom')[0] }}\"",
                              task_id="pod_task_xcom_result",
                          )

    pod_task_xcom>> pod_task_xcom_result