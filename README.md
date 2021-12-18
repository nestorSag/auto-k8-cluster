# DevOps/MLOps sandbox

This project is a small testing ground for some popular DevOps and MLOps frameworks. As of now, the repository bootstraps a Kubernetes cluster on EC2 roughly following the 'Kubernetes The Hard Way' tutorial, but using Ansible and Terraform to streamline the whole process.

## Requirements

This project assumes a 64-bit Linux OS with the following dependencies already installed

1. Python, 3.8+ (versions 2.7 and 3.4+ are untested but probably work too)
2. Terraform
3. Ansible
4. AWS CLI, AWS credentials and permissions
5. GNU make

### Bootstrapping a Kubernetes cluster

Parameters such as the number of controller nodes and worker nodes can be edited in the `tf/variables.tf` file. 

1. Make sure the environment variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are set and that the corresponding user has appropriate permissions. The policy in `tf/iam-policy/` can be used to this end.

2. From the root folder, run `make get-binaries && export PATH=$(pwd)/bin:$PATH`. This will download precompiled binaries for `kubectl`, `cfssl` and `cfssljson` to the `bin` folder and add it to the PATH. 

3. Run `make k8-cluster`. This might take a few minutes.