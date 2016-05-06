#!/bin/sh

EC2_REGION=`wget -q -O - http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region`

sed -i.bak "s/us-east-1/${EC2_REGION}/" /var/awslogs/etc/aws.conf
sed -i.bak "s/us-east-1/${EC2_REGION}/" /root/.aws/config

service awslogs restart
