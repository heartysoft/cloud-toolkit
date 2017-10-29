#!/bin/sh

set -e

. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/kubernetes-functions.sh"

configure_helm () {
  CERTIFICATES_LOCATION=${CERTIFICATES_LOCATION:-"/usr/local/certificates"}

  configure_kubernetes

  echo "setting up helm..."

  SSL_CA_BUNDLE_FILE=/etc/ssl/certs/ca-certificates.crt
  export HELM_REPO=helmet
  export HELM_REPO_CRT_FILE=$CERTIFICATES_LOCATION/helm/client.crt
  export HELM_REPO_KEY_FILE=$CERTIFICATES_LOCATION/helm/client.key

  if [ ! -f $HELM_REPO_CRT_FILE ]; then
    echo "placing base64 encoded helm crt in $HELM_REPO_CRT_FILE"
    mkdir -p $CERTIFICATES_LOCATION/helm
    echo $HELM_REPO_CRT | base64 -d > $HELM_REPO_CRT_FILE
  fi

  if [ ! -f $HELM_REPO_KEY_FILE ]; then
    echo "placing base64 encoded helm key in $KUBE_CA_KEY_FILE"
    mkdir -p $CERTIFICATES_LOCATION/helm
    echo $HELM_REPO_KEY | base64 -d > $HELM_REPO_KEY_FILE
  fi

  helm init --client-only
  helm repo add $HELM_REPO $HELM_REPO_URL/charts/ --ca-file $SSL_CA_BUNDLE_FILE --cert-file $HELM_REPO_CRT_FILE --key-file $HELM_REPO_KEY_FILE
}

# $1 - Chart.yaml location, i.e. ./mychart
# $2 - env variable name, i.e CHART_NAME
# $3 - field name, i.e. name
#
export_chart_yaml_field () {
  export $2=$(grep -Po "(?<=$3: ).*" "$1/Chart.yaml" | head -n 1)
}

# $1 - chart folder, i.e. helm/mychart
#
package_chart () {
  echo "packaging chart..."
  helm package $1
}

# $1 - namespace, i.e. default
# $2 - release name, i.e. mychart-dev
# $3 - chart to deploy, i.e. ./helm/mycart or helmet/mychart
# $4 - version, i.e. 1.0.3
#
release_chart () {
  if [ -z $4 ]; then
    helm upgrade --install --namespace $1 --debug --wait $2 $3
  else
    helm upgrade --install --namespace $1 --version $4 --debug --wait $2 $3
  fi
}

replace_env_in_file () {
  envsubst "$1" < "$2" > /tmp/replaced && mv /tmp/replaced "$2"
}

# $1 - chart name, i.e. mychart
# $2 - chart version, i.e. 1.2.3-aabbccdd
#
upload_chart () {
  echo "uploading chart..."
  curl -k --cert-type pem --cert $HELM_REPO_CRT_FILE --key $HELM_REPO_KEY_FILE -v -T ./$1-$2.tgz -X PUT $HELM_REPO_URL/upload/
}

# $1 - namespace, i.e. default
# $2 - release name, i.e. mychart-dev
# $3 - chart to deploy, i.e. ./helm/mycart or helmet/mychart
# $4 - timeout in secs, i.e 30
#S
validate_chart () {
  set -e

  NAME="$2-test-$(date +%s)"

  release_chart $1 $NAME $3

  HELM_COMMAND="helm test $NAME --cleanup"

  if [ -n "$4" ]; then
    HELM_COMMAND="$HELM_COMMAND --timeout $4"
  fi

  eval $HELM_COMMAND

  helm delete --purge $NAME
}
