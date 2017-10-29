#!/bin/sh

set -e

configure_aws () {
  set -e

  mkdir -p ~/.aws

  rm -rf ~/.aws/*

  profile_name=${AWS_PROFILE_NAME:-aws-user}

  echo "[default]" >> ~/.aws/config
  echo "region=$REGION" >> ~/.aws/config

  if [ ! -z $ROLE_ARN ]; then
    echo "role_arn=$ROLE_ARN" >> ~/.aws/config
  fi

  echo "source_profile=$profile_name" >> ~/.aws/config

  if [ ! -z $EXTERNAL_ID ]; then
    echo "external_id=$EXTERNAL_ID" >> ~/.aws/config
  fi

  echo "" >> ~/.aws/config

  echo "[profile $profile_name]" >> ~/.aws/config
  echo "region=$REGION" >> ~/.aws/config

  if [ ! -z $ROLE_ARN ]; then
    echo "role_arn=$ROLE_ARN" >> ~/.aws/config
  fi

  echo "source_profile=$profile_name" >> ~/.aws/config

  if [ ! -z $EXTERNAL_ID ]; then
    echo "external_id=$EXTERNAL_ID" >> ~/.aws/config
  fi

  echo "[$profile_name]" >> ~/.aws/credentials
  echo "aws_access_key_id=$AWS_ACCESS_KEY_ID" >> ~/.aws/credentials
  echo "aws_secret_access_key=$AWS_SECRET_ACCESS_KEY" >> ~/.aws/credentials

  if [ ! -z $ROLE_ARN ]; then
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
  fi
}

login_to_aws () {
  $(aws ecr get-login --profile builder)
}