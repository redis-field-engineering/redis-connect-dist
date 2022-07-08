kubectl create namespace vault
kubectl config set-context --current --namespace=vault
helm install vault hashicorp/vault --namespace vault -f override-values.yaml
