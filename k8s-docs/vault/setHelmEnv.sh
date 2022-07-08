# NAMESPACE where the Vault service is running.
export NAMESPACE=vault
# REC_NAMESPACE where the REC service is running.
export REC_NAMESPACE=demo
# SERVICE is the name of the Vault service in Kubernetes.
export SERVICE="vault"
# SECRET_NAME to create in the Kubernetes secrets store.
export SECRET_NAME='vault-server-tls'
# TMPDIR is a temporary working directory.
export TMPDIR='/tmp'
