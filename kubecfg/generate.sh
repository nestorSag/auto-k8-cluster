# This file generates kubeconfig and encryption configuration files. It is supposed to be called by the makefile in the root folder

rm -f ./kubecfg/*.kubeconfig

LOAD_BALANCER_DNS=$((cd tf/ && terraform output -json) | python py/get-lb-dns.py)
export ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

# kubelet Kubernetes configuration files

for worker_csrs in pki/worker-csrs/*; do
  instance=$(basename "$worker_csrs" "-csr.json")
  #echo "$instance"
  kubectl config set-cluster mlops-cluster \
    --certificate-authority=./pki/pem/ca.pem \
    --embed-certs=true \
    --server=https://${LOAD_BALANCER_DNS}:6443 \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-credentials system:node:${instance} \
    --client-certificate=./pki/pem/${instance}.pem \
    --client-key=./pki/pem/${instance}-key.pem \
    --embed-certs=true \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-context default \
    --cluster=mlops-cluster \
    --user=system:node:${instance} \
    --kubeconfig=${instance}.kubeconfig

  kubectl config use-context default --kubeconfig=${instance}.kubeconfig
done

# kube-proxy Kubernetes configuration files
kubectl config set-cluster mlops-cluster \
  --certificate-authority=./pki/pem/ca.pem \
  --embed-certs=true \
  --server=https://${LOAD_BALANCER_DNS}:6443 \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-credentials system:kube-proxy \
  --client-certificate=./pki/pem//kube-proxy.pem \
  --client-key=./pki/pem/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-context default \
  --cluster=mlops-cluster \
  --user=system:kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig


# kube-controller-manager Kubernetes configuration files
kubectl config set-cluster mlops-cluster \
  --certificate-authority=./pki/pem/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=./pki/pem/kube-controller-manager.pem \
  --client-key=./pki/pem/kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context default \
  --cluster=mlops-cluster \
  --user=system:kube-controller-manager \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig


# kube-scheduler Kubernetes configuration files
kubectl config set-cluster mlops-cluster \
  --certificate-authority=./pki/pem/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
  --client-certificate=./pki/pem/kube-scheduler.pem \
  --client-key=./pki/pem/kube-scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-context default \
  --cluster=mlops-cluster \
  --user=system:kube-scheduler \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig


# admin Kubernetes configuration files
kubectl config set-cluster mlops-cluster \
  --certificate-authority=./pki/pem/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=admin.kubeconfig

kubectl config set-credentials admin \
  --client-certificate=./pki/pem/admin.pem \
  --client-key=./pki/pem/admin-key.pem \
  --embed-certs=true \
  --kubeconfig=admin.kubeconfig

kubectl config set-context default \
  --cluster=mlops-cluster \
  --user=admin \
  --kubeconfig=admin.kubeconfig

kubectl config use-context default --kubeconfig=admin.kubeconfig

mv *.kubeconfig kubecfg/

# create encryption configuration 
(envsubst < ./pki/config/encryption-config.yaml) > ./kubeyaml/encryption-config.yaml