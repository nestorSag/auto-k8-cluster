SHELL=/bin/bash

CFSSL_URL=https://github.com/cloudflare/cfssl/releases/download/v1.6.1/cfssl_1.6.1_linux_amd64
CFSSLJSON_URL=https://github.com/cloudflare/cfssl/releases/download/v1.6.1/cfssljson_1.6.1_linux_amd64
KUBECTL_URL=https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kubectl

define get_binary
  if [ "$$(which $2)" = "" ]; then\
	  echo "$2 not present; downloading to ./bin";\
	  echo "./bin/$2";\
	  wget -q --show-progress --https-only --timestamping -O "./bin/$2" $1;\
	  chmod +x "./bin/$2";\
	  echo "add ./bin to PATH";\
	fi
endef

define create-ca
  mkdir -p pki/pem;\
  mkdir -p pki/csr;\
	cfssl gencert -initca pki/service-csrs/ca-csr.json | cfssljson -bare ca;\
	mv ca.pem pki/pem;\
	mv ca-key.pem pki/pem;\
	mv ca.csr pki/csr
endef

define sign-certificate
  FILENAME="$$(basename $1 -csr.json)";\
  cfssl gencert \
	  -ca=./pki/pem/ca.pem \
	  -ca-key=./pki/pem/ca-key.pem \
	  -config=./pki/config/ca-config.json \
	  -profile=kubernetes \
	  "$1" | cfssljson -bare "$${FILENAME}";\
	mv "$${FILENAME}.pem" pki/pem;\
	mv "$${FILENAME}-key.pem" pki/pem;\
	mv "$${FILENAME}.csr" pki/csr
endef

setup: ## downloads precompiled versions of cfssl, cfssljson and kubectl to ./bin/ if not found in PATH
	@mkdir -p bin;\
	$(call get_binary, ${CFSSL_URL},cfssl);\
	$(call get_binary, ${CFSSLJSON_URL},cfssljson);\
	$(call get_binary, ${KUBECTL_URL},kubectl);

ca: ## Creates a certificate authority
	$(call create-ca);

check-ssh-key: ## check that client's default public key file exists
	@if [ ! -f "$${HOME}/.ssh/id_rsa.pub" ]; then\
		echo "set ~/.ssh/id_rsa.pub for accessing AWS instances through SSH";\
		exit 1;\
	fi

check-aws-cli: ## Check AWS credentials are set 
	@if [ -z "$${AWS_ACCESS_KEY_ID}" ] | [ -z "$${AWS_SECRET_ACCESS_KEY}" ];then\
		echo "please set AWS secret access key and access key ID as environment variables first.";\
		exit 1;\
	fi

check-ansible: ## Check if Ansible is installed
	@if [ "$$(which ansible-playbook)" = "" ]; then\
		echo "please install Ansible first.";\
		exit 1;\
	fi

certs: ## create cluster certificates
	@cat ./tf_output.json | python py/create-worker-csrs.py;\
	cat ./tf_output.json | python py/create-api-csr.py;\
	for crs in ./pki/worker-csrs/*; do\
		$(call sign-certificate,$${crs});\
	done;\
	$(call sign-certificate,./pki/api-csr/api-csr.json);\
	$(call sign-certificate,./pki/service-csrs/admin-csr.json);\
	$(call sign-certificate,./pki/service-csrs/kube-controller-manager-csr.json);\
	$(call sign-certificate,./pki/service-csrs/kube-proxy-csr.json);\
	$(call sign-certificate,./pki/service-csrs/kube-scheduler-csr.json);\
	$(call sign-certificate,./pki/service-csrs/service-account-csr.json);

	
cluster-infra: ## Provisions the cluster infrastructure in AWS using Terraform. Save node and LB IPs in a JSON file
	@echo "Planning.."
	cd tf/ && terraform plan -out=../tf_plan.json && terraform apply ../tf_plan.json
	echo "$$(cd tf/ && terraform output -json)" > ./tf_output.json
	echo "Terraform output saved as tf_output.json; plan saved as tf_plan.json"

cluster-config: ## Configure cluster nodes using Ansible
	@./kubecfg/generate.sh;\
	rm -f ./services/* ./network-conf/* ./tf/route-*;\
	cat ./tf_output.json | python py/create-ansible-inventory.py;\
	cat ./tf_output.json | python py/create-etcd-service-files.py;\
	cat ./tf_output.json | python py/create-kubernetes-service-files.py;\
	cat ./tf_output.json | python py/create-worker-config.py;\
	ansible-playbook ansible/copy-config-to-controllers.yaml -i ./ansible/hosts -f 4;\
	ansible-playbook ansible/copy-config-to-workers.yaml -i ./ansible/hosts -f 4;\
	ansible-playbook ansible/bootstrap-etcd.yaml -i ./ansible/hosts -f 4;\
	ansible-playbook ansible/bootstrap-control-plane.yaml -i ./ansible/hosts -f 4;\
	ansible-playbook ansible/bootstrap-data-plane.yaml -i ./ansible/hosts -f 4

cluster-networking: ## Configure cluster routing and DNS
	@cat ./tf_output.json | python py/create-cidr-routes.py;\
	cd tf/ && terraform apply --auto-approve;\
	kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns-1.8.yaml;\

shutdown: ## Shuts down the cluster and destroy its resources; unsets corresponding kubectl config and deletes dynamically created tf files
	@cd tf/ && terraform destroy -auto-approve;\
	kubectl config unset contexts.mlops-cluster;\
	kubectl config unset users.admin;\
	kubectl config unset clusters.mlops-cluster;\
	rm -f ./tf/route-*;\

cluster:  ## Bootstrap Kubernetes cluster
cluster: check-ssh-key check-aws-cli check-ansible
	@$(MAKE) cluster-infra;\
	$(MAKE) certs;\
	$(MAKE) cluster-config;\
	$(MAKE) cluster-networking;\
	echo "Cluster set as default in kubectl; admin user set as default"

# kubeconfig:
# 	./kubecfg/generate.sh

help:  ## Shows Makefile's help.
	@sed -ne '/@sed/!s/## //p' $(MAKEFILE_LIST)
	
	
	



