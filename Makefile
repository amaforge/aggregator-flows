.PHONY: build push deploy ns destroy restart update ui clean  

#################################################################################
# GLOBALS                                                                       #
#################################################################################

##################################s###############################################
# COMMANDS                                                                      #
#################################################################################

build:
	docker build -t aggregator/airflow:latest -f config/docker/Dockerfile .
	
push:
	docker tag aggregator/airflow:latest gcr.io/amaforge-scry/aggregator-airflow
	docker push gcr.io/amaforge-scry/aggregator-airflow

ns:
	kubectl create namespace airflow;
	
deploy:
	kubectl apply -f config/kube/airflow-credentials.secret.yaml 
	kubectl apply -f config/kube/airflow-role-binding.yaml
	kubectl apply -f config/kube/postgres.yaml
	kubectl apply -f config/kube/configmap.yaml
	kubectl apply -f config/kube/volumes.yaml
	kubectl apply -f config/kube/pvc.yaml
	kubectl apply -f config/kube/airflow.yaml

update:
	make build
	make push
	kubectl rollout restart deployment/airflow -n=airflow

restart:
	make destroy
	make build
	make push
	make deploy
	kubectl rollout restart deployment/airflow -n=airflow

ui:
	kubectl -n airflow port-forward $(pod) 8092:8092

clean:
	docker stop $(docker ps -a -q)
	docker rm -v $(docker ps -a -q)
	docker rmi $(docker images -a -q)