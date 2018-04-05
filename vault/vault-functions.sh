#!/usr/bin/bash

set -e

# $1 - environment, i.e. dev, prod
#
export_vault_config() {
  ENV=$(echo "$1" | tr '[:lower:]'  '[:upper:]' )
  ADDR=$(eval "echo \$VAULT_ADDR_$ENV")
  TOKEN=$(eval "echo \$VAULT_TOKEN_$ENV")
  if [ -n "$ADDR" ]; then
    export VAULT_ADDR=$ADDR
  fi
  if [ -n "$TOKEN" ]; then
    export VAULT_TOKEN=$TOKEN
  fi
}

# $1 - product group
#
read_amazon_ecr_environment () {
  read_secret "secret/$1/amazon/ecr/accesskey"
  export AWS_ACCESS_KEY_ID=$secret_value
  read_secret "secret/$1/amazon/ecr/account"
  export AWS_ACCOUNT=$secret_value
  read_secret "secret/$1/amazon/ecr/secretaccesskey"
  export AWS_SECRET_ACCESS_KEY=$secret_value
  read_secret "secret/$1/amazon/ecr/externalid"
  export EXTERNAL_ID=$secret_value
  read_secret "secret/$1/amazon/ecr/region"
  export REGION=$secret_value
  read_secret "secret/$1/amazon/ecr/rolearn"
  export ROLE_ARN=$secret_value
}

# $1 - product group, i.e. datalake
# $2 - environment, i.e. dev, prod
#
read_helm_environment () {
  read_kubernetes_environment $1 $2

  read_secret "secret/$1/helm/certificate"
  export HELM_REPO_CRT=$secret_value
  read_secret "secret/$1/helm/key"
  export HELM_REPO_KEY=$secret_value
  read_secret "secret/$1/helm/url"
  export HELM_REPO_URL=$secret_value
}

# $1 - product group, i.e. datalake
# $2 - environment, i.e. dev, prod
#
read_kubernetes_environment () {
  read_secret "secret/$1/kubernetes/$2/certificate"
  export KUBE_CA_PEM=$secret_value
  read_secret "secret/$1/kubernetes/$2/namespace"
  export KUBE_NAMESPACE=$secret_value
  read_secret "secret/$1/kubernetes/$2/token"
  export KUBE_TOKEN=$secret_value
  read_secret "secret/$1/kubernetes/$2/url"
  export KUBE_URL=$secret_value
}

# $1 - path to secret with want to read
read_secret () { 
  secret_value=`curl -s -H "X-Vault-Token:$VAULT_TOKEN" "$VAULT_ADDR/v1/$1" | jq --raw-output '.data.value'`
  [[ ! -z $secret_value ]]
}
