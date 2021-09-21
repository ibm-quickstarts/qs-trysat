#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

LOCATION_NAME=$1
IPADDR1=$2
IPADDR2=$3
IPADDR3=$4

function register() {
    echo "try-sat WARNING; the following command may fail (see https://ibm-garage.slack.com/archives/C01149RMSCU/p1623773919101700). This is to be expected and a known problem right now; try-sat should work around this."
    ibmcloud sat location dns register --ip "${IPADDR1}" --ip "${IPADDR2}" --ip "${IPADDR3}" --location "${LOCATION_NAME}" || true
}

register
until ibmcloud sat location dns ls --location "${LOCATION_NAME}" | grep "${IPADDR1}"; do
    echo "DNS records not yet ready, retrying in 60s..."
    sleep 60
    register
done
