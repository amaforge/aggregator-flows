.PHONY: build push deploy ns cwagent fluentd destroy restart kubedash ui clean  

#################################################################################
# GLOBALS                                                                       #
#################################################################################

##################################s###############################################
# COMMANDS                                                                      #
#################################################################################

build:
	docker build -t aggregator/airflow:latest -f config/docker/Dockerfile .
	
push:
	aws ecr get-login --no-include-email --region us-west-1 --no-verify-ssl | echo $($0)
	docker tag aggregator/airflow:latest gcr.io/amaforge-scry/aggregator-airflow
	docker push gcr.io/amaforge-scry/aggregator-airflow

ns:
	kubectl create namespace airflow;
	
deploy:
	kubectl apply -f config/kube/git-credentials.secret.yaml --namespace airflow
	kubectl apply -f config/kube/airflow-role-binding.yaml --namespace airflow
	helm install -f config/helm/charts/airflow-{{ cookiecutter.airflow_executor.lower() }}.yaml --namespace airflow airflow stable/airflow

restart:
	make destroy
	make ns
	make deploy

ui:
	kubectl -n airflow port-forward $(pod) 8080:8080

clean:
	docker stop $(docker ps -a -q)
	docker rm -v $(docker ps -a -q)
	docker rmi $(docker images -a -q)