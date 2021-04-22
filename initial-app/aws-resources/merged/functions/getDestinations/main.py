import os
import json
import boto3
import logging

import redis

redis_host = os.environ['redis_host']
cache_data = []
def lambda_handler(event, context):
    try:
        logging.info('LOADED')
        client = redis.Redis(host=redis_host, port = 6379, db = 0)
        destinations = []

        cache_data = client.get('destinations')

        if cache_data:
            destinations = json.loads(cache_data)['primary_destination_id']

        return {
            'statusCode': 200,
            'headers': {
                "Access-Control-Allow-Origin" : "*", # Required for CORS support to work
            },
            'body': json.dumps([{i: destinations[i]} for i in list(destinations.keys())])
        }


    except:
        return {
            'statusCode': 400,
            'headers': {
                "Access-Control-Allow-Origin" : "*", # Required for CORS support to work
            },
            'body': json.dumps([])
        }