SHELL=/bin/bash

.PHONY= ca

CFSSL_URL=https://github.com/cloudflare/cfssl/releases/download/v1.6.1/cfssl_1.6.1_linux_amd64
CFSSLJSON_URL=https://github.com/cloudflare/cfssl/releases/download/v1.6.1/cfssljson_1.6.1_linux_amd64
KUBECTL_URL=https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kubectl

define get_ips
  cd tf/ && terraform output -json $1 | python -c "import json, sys; print(','.join(json.load(sys.stdin).values()))"
endef 

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

define make-service-keys
  cfssl gencert \
	  -ca=./pki/pem/ca.pem \
	  -ca-key=./pki/pem/ca-key.pem \
	  -config=./pki/config/ca-config.json \
	  -profile=kubernetes \
	  "./pki/service-csrs/$1.json" | cfssljson -bare "$1";\
	mv "$1.pem" pki/pem;\
	mv "$1-key.pem" pki/pem;\
	mv $1.csr pki/csr
endef

define make-worker-keys
  for path in pki/worker-csrs/*; do\
    filename="$$(basename $${path})";\
	  cfssl gencert \
      -ca=pki/pem/ca.pem \
      -ca-key=pki/pem/ca-key.pem \
      -config=pki/config/ca-config.json \
      -hostname="$${filename}" \
      -profile=kubernetes \
      "$${path}" | cfssljson -bare "$${filename}";\
    mv "$${filename}.pem" pki/pem;\
	  mv "$${filename}-key.pem" pki/pem;\
	  mv "$${filename}.csr" pki/csr;\
	done
endef

get-binaries: ## downloads precompiled versions of cfssl, cfssljson and kubectl to ./bin/ if not found in PATH
	@mkdir -p bin
	@$(call get_binary, ${CFSSL_URL},cfssl);
	@$(call get_binary, ${CFSSLJSON_URL},cfssljson);
	@$(call get_binary, ${KUBECTL_URL},kubectl);

check-public-key: ## check that client's default public key file exists
	@if [ ! -f "$${HOME}/.ssh/id_rsa.pub" ]; then\
		echo "set ~/.ssh/id_rsa.pub for accessing AWS instances through SSH";\
		exit 1;\
	fi

aws-cli-check: ## Check AWS credentials are set 
	@if [ -z "$${AWS_ACCESS_KEY_ID}" ] | [ -z "$${AWS_SECRET_ACCESS_KEY}" ];then\
		echo "please set AWS secret access key and access key ID as environment variables first.";\
		exit 1;\
	fi

ansible-check: ## Check if Ansible is installed
	@if [ "$$(which ansible-playbook)" = "" ]; then\
		echo "please install Ansible first.";\
		exit 1;\
	fi

ca: ## Create public key infrastructure
	$(call create-ca);

service-keys: #create K8 services' key pairs
	@$(call make-service-keys,admin-csr);\
	$(call make-service-keys,kube-controller-manager-csr);\
  $(call make-service-keys,kube-proxy-csr);\
  $(call make-service-keys,kube-scheduler-csr);\
  $(call make-service-keys,kubernetes-csr);\
  $(call make-service-keys,service-account-csr);\
  $(call make-service-keys,service-account-csr);

worker-keys: #create Kubelet key pars for each worker node
	@echo "$$(cd tf/ && terraform output -json)" | python3 py/create-worker-csrs.py;\
  $(call make-worker-keys);

help:  ## Shows Makefile's help.
	@sed -ne '/@sed/!s/## //p' $(MAKEFILE_LIST)
	
	
	



