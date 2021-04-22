import os
import json
import boto3
import logging
import pandas as pd
from io import StringIO

import redis


redis_host = os.environ['redis_host']

bucket = os.environ['bucket_name']
s3 = boto3.resource('s3')
destObj = s3.Object(bucket, 'kaligo_inventory_prod_destinations.csv')

hotelObj = s3.Object(bucket, 'kaligo_inventory_prod_hotels.csv')
hotelBody = hotelObj.get()['Body'].read().decode('utf-8')


def lambda_handler(event, context):
    logging.info('LOADED')

    destBody = destObj.get()['Body'].read().decode('utf-8')
    df_destinations = pd.read_csv(StringIO(destBody))

    df_hotels = pd.read_csv(StringIO(hotelBody))

    df_destinations = df_destinations.rename(columns={'uid':'primary_destination_id'})
    matched_df = df_destinations.merge(df_hotels, on=['primary_destination_id'], how='inner')

    filtered_df = matched_df[['primary_destination_id','full_name','uid','rating','name_y']].rename(columns={"name_y": "hotel"})

    jsonString = filtered_df[['full_name','primary_destination_id']].apply(lambda x: x.drop_duplicates()).set_index('full_name').to_json()

    hotels = filtered_df[['full_name','primary_destination_id','hotel','uid']].groupby('full_name').apply(lambda x: json.loads(x[['primary_destination_id','hotel','uid']].to_json(orient='records')))
    update_cache(jsonString, hotels)
    # new_cache = json.loads(jsonString)

    return {
        'statusCode': 200,
        'headers': {
            "Access-Control-Allow-Origin" : "*", # Required for CORS support to work
        },
        # 'body': new_cache
    }

def update_cache(new_cache, hotels):

    client = redis.Redis(host=redis_host, port = 6379, db = 0)
    client.set('destinations', new_cache)

    for key in hotels.keys():
        client.set(key, json.dumps(hotels[key]))