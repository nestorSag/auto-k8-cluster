setup: ## downloads precompiled versions of cfssl, cfssljson and kubectl to ./bin/ if not already there
	@mkdir -p bin
	@echo "checking for cfssl .."
	@if [ ! -f "bin/cfssl" ];then \
		echo "downloading cfssl..";\
		wget -q --show-progress --https-only --timestamping --directory-prefix=./bin/ https://github.com/cloudflare/cfssl/releases/download/v1.6.1/cfssl_1.6.1_linux_amd64;\
		chmod +x bin/cfssl_1.6.1_linux_amd64;\
		mv bin/cfssl_1.6.1_linux_amd64 bin/cfssl;else\
		echo "found";fi\

	@mkdir -p bin
	@echo "checking for cfssljson .."
	@if [ ! -f "bin/cfssljson" ];then \
		echo "downloading cfssljson..";\
		wget -q --show-progress --https-only --timestamping --directory-prefix=./bin/ https://github.com/cloudflare/cfssl/releases/download/v1.6.1/cfssljson_1.6.1_linux_amd64;\
		chmod +x bin/cfssljson_1.6.1_linux_amd64;\
		mv bin/cfssljson_1.6.1_linux_amd64 bin/cfssljson;else\
		echo "found";fi\

	@mkdir -p bin
	@echo "checking for kubectl .."
	@if [ ! -f "bin/kubectl" ];then \
		echo "downloading kubectl..";\
		wget -q --show-progress --https-only --timestamping --directory-prefix=./bin/ https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kubectl;\
		chmod +x bin/kubectl;else\
		echo "found";fi\

terraform: ## Bootstraps cloud infrastructure in AWS to host the Kubernetes cluster
	# checks that AWS credentials are present
	if [ -z "${AWS_ACCESS_KEY_ID}" ] | [ -z "${AWS_SECRET_ACCESS_KEY}" ];then\
		echo "please set environment variables for AWS credentials: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY";\
	  exit 64;else\
	  

	
	



