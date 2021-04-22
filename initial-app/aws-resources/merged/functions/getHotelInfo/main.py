import requests
import json


def lambda_handler(event, context):

    params = event['pathParameters']
    if params == None:
        return {
            "statusCode": 400,
            'headers': {
                "Access-Control-Allow-Origin": "*"
            },
            'body': str(event)
        }
    try:
        hotel = params['hotel']

        response = requests.get(f'https://hotelapi.loyalty.dev/api/hotels/{hotel}').text
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
            'body': json.dumps("error")
        }
