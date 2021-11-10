#!/bin/bash

mkdir -p tokens

vault write identity/oidc/key/oidc-key-api \
    allowed_client_ids="consul-cluster-dc1"

vault write identity/oidc/role/oidc-role-api \
    ttl=12h key="oidc-key-api" client_id="consul-cluster-dc1" \
    template="{\"consul\": {\"hostname\": \"${API_NODE_NAME}\" } }"

vault policy write oidc-policy-api policies/vault_api_policy.json

vault write auth/userpass/users/api password=password policies=oidc-policy-api

vault login -method=userpass username=api password=password

vault read identity/oidc/token/oidc-role-api -format=json | jq -r .data.token > tokens/jwt_api


vault write identity/oidc/key/oidc-key-web \
    allowed_client_ids="consul-cluster-dc1"

vault write identity/oidc/role/oidc-role-web \
    ttl=12h key="oidc-key-web" client_id="consul-cluster-dc1" \
    template="{\"consul\": {\"hostname\": \"${WEB_NODE_NAME}\" } }"

vault policy write oidc-policy-web policies/vault_web_policy.json

vault write auth/userpass/users/web password=password policies=oidc-policy-web

vault login -method=userpass username=web password=password

vault read identity/oidc/token/oidc-role-web -format=json | jq -r .data.token > tokens/jwt_web