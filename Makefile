DEFAULT_NAMESPACE ?= jfrog-sandbox
PGADMIN_NAMESPACE ?= pgadmin-sandbox
MASTER_KEY ?= $(shell openssl rand -hex 32)

.PHONY: switch-to-local
switch-to-local:
	cp -f ./.kube/local-ohmyglb/config ~/.kube/config

.PHONY: switch-to-270-nonprod
switch-to-270-nonprod:
	cp -f ./.kube/remote-270-nonprod/config ~/.kube/config

.PHONY: switch-to-sdc-nonprod
switch-to-sdc-nonprod:
	cp -f ./.kube/remote-sdc-nonprod/config ~/.kube/config

.PHONY: where
where:
	@kubectl config get-clusters

.PHONY: deploy-jfrog
deploy-jfrog:
	kubectl apply -f deploy/namespace.yaml
	$(call deploy-jfrog-ha)

.PHONY: deploy-pgadmin
deploy-pgadmin:
	$(call deploy-pgadmin)

.PHONY: destroy-jfrog
destroy-jfrog:
	kubectl delete -f deploy/namespace.yaml

.PHONY: jfrog-db-password
jfrog-db-password:
	@echo DB_PWD: $$(kubectl get --namespace $(DEFAULT_NAMESPACE) $$(kubectl get secret --namespace $(DEFAULT_NAMESPACE) -o name | grep postgresql) -o jsonpath="{.data.postgresql-password}"|base64 --decode)
	@echo SERVICE_IP: $$(kubectl get svc --namespace $(DEFAULT_NAMESPACE) artifactory-ha-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

define deploy-jfrog-ha
	helm repo add jfrog https://charts.jfrog.io
	helm upgrade --install artifactory-ha \
					--set artifactory.masterKey=$(MASTER_KEY) \
					--set artifactory.admin.username="admin" \
					--set artifactory.admin.password=".Password123" \
					--set artifactory.primary.resources.requests.cpu="500m" \
					--set artifactory.primary.resources.limits.cpu="2" \
					--set artifactory.primary.resources.requests.memory="1Gi" \
					--set artifactory.primary.resources.limits.memory="4Gi" \
					--set artifactory.primary.javaOpts.xms="1g" \
					--set artifactory.primary.javaOpts.xmx="4g" \
					--set artifactory.node.resources.requests.cpu="500m" \
					--set artifactory.node.resources.limits.cpu="2" \
					--set artifactory.node.resources.requests.memory="1Gi" \
					--set artifactory.node.resources.limits.memory="4Gi" \
					--set artifactory.node.javaOpts.xms="1g" \
					--set artifactory.node.javaOpts.xmx="4g" \
					--set initContainers.resources.requests.cpu="10m" \
					--set initContainers.resources.limits.cpu="250m" \
					--set initContainers.resources.requests.memory="64Mi" \
					--set initContainers.resources.limits.memory="128Mi" \
					--set postgresql.resources.requests.cpu="200m" \
					--set postgresql.resources.limits.cpu="1" \
					--set postgresql.resources.requests.memory="500Mi" \
					--set postgresql.resources.limits.memory="1Gi" \
					--set nginx.resources.requests.cpu="100m" \
					--set nginx.resources.limits.cpu="250m" \
					--set nginx.resources.requests.memory="250Mi" \
					--set nginx.resources.limits.memory="500Mi" \
					--namespace $(DEFAULT_NAMESPACE) jfrog/artifactory-ha
endef

define deploy-pgadmin
	helm repo add runix https://helm.runix.net/
	helm upgrade --install pgadmin4 \
					--set env.password=password \
					--set env.email=admin@local.com \
					--set env.service.port=83 \
					--namespace $(PGADMIN_NAMESPACE) runix/pgadmin4
endef

