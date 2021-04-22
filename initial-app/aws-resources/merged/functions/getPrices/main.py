import json
import requests

def lambda_handler(event, context):
    try:
        params = event['queryStringParameters']
        destination_id = params['destination_id']
        checkInDate = params['checkin']
        checkOutDate = params['checkout']
        guest = params['guest']
        response = None
        for i in range(5):
            response = json.loads(requests.get(f"https://hotelapi.loyalty.dev/api/hotels/prices?destination_id={destination_id}&checkin={checkInDate}&checkout={checkOutDate}&lang=en_US&currency=SGD&country_code=SG&guests={guest}&partner_id=1").text)
            if response['hotels'] != []:
                break

        return {
            "statusCode": 200,
            'headers': {
                "Access-Control-Allow-Origin": "*"
            },
            'body': json.dumps(response)
        }
    except Exception as e:
        return {
            "statusCode": 400,
            'headers': {
                "Access-Control-Allow-Origin": "*"
            },
            'body': json.dumps("error")
        }
