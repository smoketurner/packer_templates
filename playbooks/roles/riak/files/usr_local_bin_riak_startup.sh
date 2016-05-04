#!/bin/sh

FOUND=`grep -Fxq "riak@127.0.0.1" /etc/riak/riak.conf`
if [ $FOUND -eq 0 ]; then
    exit 0
fi

IP_ADDRESS=$(wget -q -O - http://169.254.169.254/latest/meta-data/local-ipv4)

service riak stop
riak-admin down riak@127.0.0.1

# remove any previous ring data
rm -rf /var/lib/riak/ring/*

sed -i.bak "s/riak@127.0.0.1/riak@${IP_ADDRESS}/" /etc/riak/riak.conf

riak-admin cluster force-replace riak@127.0.0.1 riak@{IP_ADDRESS}

service riak start
