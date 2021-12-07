SHELL = /bin/bash

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
  @mkdir -p pki/pem;\
	cfssl gencert -initca pki/config/ca-csr.json | cfssljson -bare ca;\
	mv ca.pem pki/pem;\
	mv ca-key.pem pki/pem;\
endef

define sign-cert
  cfssl gencert \
	  -ca=pki/pem/ca.pem \
	  -ca-key=pki/pem/ca-key.pem \
	  -config=pki/config/ca-config.json \
	  -profile=kubernetes \
	  "kpi/config/$1.json" | cfssljson -bare "$1";\
	mv "$1.pem" pki/pem;\
	mv "$1-key.pem" pki/pem;
endef

get-binaries: ## downloads precompiled versions of cfssl, cfssljson and kubectl to ./bin/ if not found in PATH
	@mkdir -p bin
	@$(call get_binary, ${CFSSL_URL},cfssl);
	@$(call get_binary, ${CFSSLJSON_URL},cfssljson);
	@$(call get_binary, ${KUBECTL_URL},kubectl);

aws-cli-check: ## Check AWS credentials are set 
	@if [ -z "$${AWS_ACCESS_KEY_ID}" ] | [ -z "$${AWS_SECRET_ACCESS_KEY}" ];then\
		echo "please set AWS secret access key and access key ID as environment variables first.";\
	fi

create-pki: ## Create public key infrastructure
	$(call create-ca);
	$(call sign-cert,admin-csr);
	$(call sign-cert,kube-controller-manager-csr);
	$(call sign-cert,kube-proxy-csr);
	$(call sign-cert,kube-scheduler-csr);
	$(call sign-cert,kubernetes-csr);
	$(call sign-cert,service-account-csr);

help:  ## Shows Makefile's help.
	@sed -ne '/@sed/!s/## //p' $(MAKEFILE_LIST)
	
	
	



