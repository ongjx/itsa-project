import json
import redis
import os
# This function gets hotels based on a destination

redis_host = os.environ['redis_host']
client = redis.Redis(host=redis_host, port = 6379, db = 0)

def lambda_handler(event, context):

    params = event['queryStringParameters']
    if params == None:
        return {
            "statusCode": 400,
            'headers': {
                "Access-Control-Allow-Origin": "*"
            },
            'body': json.dumps([])
        }
    try:
        destination_id = params['destination_id']
        response = client.get(destination_id)
        # response = requests.get(f"https://hotelapi.loyalty.dev/api/hotels?destination_id={destination_id}").text
        return {
            "statusCode": 200,
            'headers': {
                "Access-Control-Allow-Origin": "*"
            },
            'body': response
        }
    except Exception as e:
        return {
            "statusCode": 400,
            'headers': {
                "Access-Control-Allow-Origin": "*"
            },
            'body': json.dumps([])
        }
