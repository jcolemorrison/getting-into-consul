#!/bin/bash

export VAULT_NAMESPACE=admin

curl \
    --header "X-Vault-Token: ${VAULT_TOKEN}" \
    --header "X-Vault-Namespace: ${VAULT_NAMESPACE}" \
    --request POST \
    --data "{\"issuer\": \"$(terraform output -raw vault_addr)\"}" \
    ${VAULT_ADDR}/v1/identity/oidc/config

curl \
    --header "X-Vault-Token: ${VAULT_TOKEN}" \
    --header "X-Vault-Namespace: ${VAULT_NAMESPACE}" \
    --request GET \
    ${VAULT_ADDR}/v1/identity/oidc/.well-known/openid-configuration

vault auth enable userpass