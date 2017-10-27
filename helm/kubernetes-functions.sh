#!/bin/sh

configure_kubernetes () {
  #defensive.. kubectl --from-file adds trailing newline
  KUBE_TOKEN=`echo -n $KUBE_TOKEN` 

  CERTIFICATES_LOCATION=${CERTIFICATES_LOCATION:-"/usr/local/certificates"}
  KUBE_CA_PEM_FILE=$CERTIFICATES_LOCATION/kube/kube.ca.pem

  if [ ! -f $KUBE_CA_PEM_FILE ]; then
    echo "placing base64 encoded kubernetes pem file in $KUBE_CA_PEM_FILE"
    mkdir -p $CERTIFICATES_LOCATION/kube
    echo $KUBE_CA_PEM | base64 -d > $KUBE_CA_PEM_FILE
  fi


  if [ ! -f ~/.kube/config ]; then
    echo "generating ~/.kube/config..."
    KUBE_CLUSTER_OPTIONS=--certificate-authority="$KUBE_CA_PEM_FILE"

    kubectl config set-cluster kube-cluster --server="$KUBE_URL" $KUBE_CLUSTER_OPTIONS
    kubectl config set-credentials kube-user --token="$KUBE_TOKEN" $KUBE_CLUSTER_OPTIONS
    kubectl config set-context kube-cluster --cluster=kube-cluster --user kube-user --namespace="$KUBE_NAMESPACE"
    kubectl config use-context kube-cluster
  fi
}
