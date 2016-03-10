#!/bin/bash

# $DOMAINS should contain all domains that this container is responsible for
# renewing. The first one dictates where the cert will live.

# Inside /etc/letsencrypt/live/<domain> we have:
#
# cert.pem  chain.pem  fullchain.pem  privkey.pem
#
# We want to convert fullchain.pem into proxycert
# and privkey.pem into proxykey and then save as a secret!

if [ -z "$SECRET_NAME" ]; then
    echo "ERROR: Secret name is empty or unset"
    exit 1
fi

CERT_LOCATION='/etc/letsencrypt/live'

DOMAINS=($DOMAINS)
DOMAIN=${DOMAINS[0]}

HAPROXYKEY=$(cat $CERT_LOCATION/$DOMAIN/fullchain.pem $CERT_LOCATION/$DOMAIN/privkey.pem | base64 --wrap=0)

CERT=$(cat $CERT_LOCATION/$DOMAIN/fullchain.pem | base64 --wrap=0)
KEY=$(cat $CERT_LOCATION/$DOMAIN/privkey.pem | base64 --wrap=0)
DHPARAM=$(openssl dhparam 2048 | base64 --wrap=0)

kubectl get secrets $SECRET_NAME && ACTION=replace || ACTION=create;

cat << EOF | kubectl $ACTION -f -
{
 "apiVersion": "v1",
 "kind": "Secret",
 "metadata": {
   "name": "$SECRET_NAME",
   "namespace": "default"
 },
 "data": {
   "proxycert": "$CERT",
   "proxykey": "$KEY",
   "haproxykey": "$HAPROXYKEY",
   "dhparam": "$DHPARAM"
 }
}
EOF
