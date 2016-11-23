#!/bin/sh

export AWS_PROFILE=jplock_packer
#export PACKER_LOG=1

packer build riak.json
