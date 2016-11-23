#!/usr/bin/env python

import urllib2
import json
import datetime
import boto3


client = boto3.client('cloudwatch')


def get_instance_id():
    instanceid = urllib2.urlopen(
        'http://169.254.169.254/latest/meta-data/instance-id').read()
    return instanceid


def get_stats():
    response = urllib2.urlopen('http://127.0.0.1:8098/stats').read()
    return json.loads(response)


def publish(instance_id, stats):
    timestamp = datetime.datetime.utcnow().isoformat()

    MetricData = []
    Dimensions = [
        {
            'Name': 'InstanceId',
            'Value': instance_id
        }
    ]

    for metric in ['node_put_fsm_time_mean', 'node_get_fsm_time_mean']:
        data = {
            'MetricName': metric,
            'Dimensions': Dimensions,
            'Timestamp': timestamp,
            'Value': int(stats[metric]),
            'Unit': 'Microseconds'
        }
        MetricData.append(data)

    for metric in ['node_gets', 'node_puts']:
        data = {
            'MetricName': metric,
            'Dimensions': Dimensions,
            'Timestamp': timestamp,
            'Value': int(stats[metric]),
            'Unit': 'Count'
        }
        MetricData.append(data)

    for metric in ['mem_total', 'mem_allocated']:
        data = {
            'MetricName': metric,
            'Dimensions': Dimensions,
            'Timestamp': timestamp,
            'Value': float(stats[metric]),
            'Unit': 'Count'
        }
        MetricData.append(data)

    if 'mem_total' in stats and stats['mem_total'] > 0:
        value = int(float(stats['mem_allocated']) * 100 / float(
            stats['mem_total']))
    else:
        value = 0

    data = {
        'MetricName': 'mem_allocated_%',
        'Dimensions': Dimensions,
        'Timestamp': timestamp,
        'Value': value,
        'Unit': 'Percent'
    }
    MetricData.append(data)

    data = {
        'MetricName': 'node_get_fsm_siblings_mean',
        'Dimensions': Dimensions,
        'Timestamp': timestamp,
        'Value': int(stats['node_get_fsm_siblings_mean']),
        'Unit': 'Count'
    }
    MetricData.append(data)

    data = {
        'MetricName': 'node_get_fsm_objsize_mean',
        'Dimensions': Dimensions,
        'Timestamp': timestamp,
        'Value': int(stats['node_get_fsm_objsize_mean']),
        'Unit': 'Bytes'
    }
    MetricData.append(data)

    client.put_metric_data(Namespace='riak', MetricData=MetricData)


if __name__ == '__main__':
    instance_id = get_instance_id()
    stats = get_stats()
    publish(instance_id, stats)
