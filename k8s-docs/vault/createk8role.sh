vault write auth/kubernetes/role/redis-enterprise-database \
      bound_service_account_names=workload \
      bound_service_account_namespaces=demo \
      policies=redis-enterprise-database \
      ttl=24h
