apiVersion: v1
kind: ConfigMap
metadata:
  name: iam-ts-config
  namespace: default
data:
  admin_user: admin
  admin_password: password
  client_id: client-cred
  client_secret: secret
  token_exchange_client_id: token-exchange-actor
  token_exchange_client_secret: secret
