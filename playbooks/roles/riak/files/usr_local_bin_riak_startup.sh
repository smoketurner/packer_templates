#!/bin/bash

set -xeuo pipefail

grep -Fq "riak@127.0.0.1" /etc/riak/riak.conf
FOUND=$?

if [ $FOUND -eq 1 ]; then
    exit 0
fi

IP_ADDRESS=`wget -q -O - http://169.254.169.254/latest/meta-data/local-ipv4`
echo "Discovered IP address: ${IP_ADDRESS}"

EC2_REGION=`wget -q -O - http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region`
echo "Discovered EC2 region: ${EC2_REGION}"

sed -i.bak "s/us-east-1/${EC2_REGION}/" /root/.aws/config

echo "Stopping Riak..."
service riak hardstop || true

echo "Bringing down riak@127.0.0.1..."
riak-admin down riak@127.0.0.1 || true

echo "Removing existing ring and cluster_meta data..."
rm -rf /var/lib/riak/ring/*
rm -rf /var/lib/riak/cluster_meta/*

echo "Updating riak.conf nodename=riak@${IP_ADDRESS}..."
sed -i.bak "s/riak@127.0.0.1/riak@${IP_ADDRESS}/" /etc/riak/riak.conf

echo "Replacing old Riak node with riak@${IP_ADDRESS}..."
riak-admin cluster force-replace riak@127.0.0.1 riak@${IP_ADDRESS} || true

echo "Resetting Riak startup priorities..."
chkconfig riak reset

echo "Starting Riak..."
service riak start
