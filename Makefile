DEFAULT_NAMESPACE ?= jfrog-sandbox

.PHONY: switch-to-local
switch-to-local:
	cp -f ./.kube/local-ohmyglb/config ~/.kube/config

.PHONY: switch-to-270-nonprod
switch-to-270-nonprod:
	cp -f ./.kube/remote-270-nonprod/config ~/.kube/config

.PHONY: switch-to-sdc-nonprod
switch-to-sdc-nonprod:
	cp -f ./.kube/remote-sdc-nonprod/config ~/.kube/config


.PHONY: deploy-jfrog
deploy-jfrog:
	$call(deploly-jfrog-ha)

.PHONY: deploy-pgadmin
deploy-pgadmin:
	helm repo add runix https://helm.runix.net/
	helm upgrade --install pgadmin4 --set env.password=password --set env.email=admin@local.com --namespace $(DEFAULT_NAMESPACE) runix/pgadmin4

.PHONY: destroy-jfrog
destroy-jfrog:
	kubectl delete -f deploy/namespace.yaml

define deploly-jfrog-ha
	kubectl apply -f deploy/namespace.yaml
	helm repo add jfrog https://charts.jfrog.io
	export MASTER_KEY=$(openssl rand -hex 32)
	@echo MASTER_KEY: ${MASTER_KEY}
	helm upgrade --install artifactory-ha --set artifactory.masterKey=${MASTER_KEY} --namespace $(DEFAULT_NAMESPACE) jfrog/artifactory-ha
	export DB_PASSWORD=$(kubectl get --namespace jfrog-sandbox $(kubectl get secret --namespace jfrog-sandbox -o name | grep postgresql) -o jsonpath="{.data.postgresql-password}" | base64 --decode)
	@echo DB_PASSWORD: ${DB_PASSWORD}
endef
