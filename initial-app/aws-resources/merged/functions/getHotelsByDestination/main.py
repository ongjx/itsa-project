import requests
import json
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
        checkin = params['checkin']
        checkout = params['checkout']
        guests = params['guest']

        url = f"https://hotelapi.loyalty.dev/api/hotels/?destination_id={destination_id}&checkin={checkin}&checkout={checkin}&guests={guests}&lang=en_US&currency=SGD&country_code=SG&partner_id=1"

        response = requests.get(url).text
        return {
            "statusCode": 200,
            'headers': {
                "Access-Control-Allow-Origin": "*"
            },
            'body': response
        }
    except:
        return {
            "statusCode": 400,
            'headers': {
                "Access-Control-Allow-Origin": "*"
            },
            'body': json.dumps([])
        }