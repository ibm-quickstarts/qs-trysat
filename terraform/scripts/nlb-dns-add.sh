#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

CLUSTER_NAME=$1
NLB_IP_1=$2
NLB_IP_2=$3
NLB_IP_3=$4

NLB_HOST=$(ibmcloud ks nlb-dns ls --cluster "${CLUSTER_NAME}" | tail -1 | cut -f1 -d' ')

# Sometimes the following line appears to have failed, but actually
# passed, which is why we then check with 'nlb-dns ls'. We assume that if one IP
# is there, they all are.
ibmcloud ks nlb-dns add --cluster "${CLUSTER_NAME}" --nlb-host "${NLB_HOST}" --ip "${NLB_IP_1}" --ip "${NLB_IP_2}" --ip "${NLB_IP_3}" || true
until ibmcloud ks nlb-dns ls --cluster "${CLUSTER_NAME}" | grep "${NLB_IP_1}" > /dev/null; do 
    echo "Waiting to add NLB IPs..."; sleep 30;
    ibmcloud ks nlb-dns add --cluster "${CLUSTER_NAME}" --nlb-host "${NLB_HOST}" --ip "${NLB_IP_1}" --ip "${NLB_IP_2}" --ip "${NLB_IP_3}" || true
done
echo "IPs successfully added."
