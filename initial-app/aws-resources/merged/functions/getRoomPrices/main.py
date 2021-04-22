import requests
import json

# Get prices of rooms in one hotel
def lambda_handler(event, context):
    try:
        params = event['queryStringParameters']
        hotel = params['hotel']
        destination_id = params['destination_id']
        checkInDate = params['checkin']
        checkOutDate = params['checkout']
        guest = params['guest']
        for i in range(3):
            response = requests.get(f"https://hotelapi.loyalty.dev/api/hotels/{hotel}/price?destination_id={destination_id}&checkin={checkInDate}&checkout={checkOutDate}&lang=en_US&currency=SGD&country_code=SG&guests={guest}&partner_id=1").text
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