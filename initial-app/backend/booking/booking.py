from flask import Flask, request,jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from os import environ

import decimal
import datetime
import re

# from os import environ

app = Flask(__name__)

app.config['SQLALCHEMY_DATABASE_URI'] = environ.get('dbURL')#'mysql+mysqlconnector://root@localhost:3306/itsa'

app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

CORS(app)

EMAIL_REGEX = r'''(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])'''

class Booking(db.Model):
    __tablename__ = 'booking'

    bookingID = db.Column(db.Integer, primary_key = True, autoincrement = True)
    customerEmail = db.Column(db.String(255), nullable = False)
    customerName = db.Column(db.String(255), nullable = False)
    hotelID = db.Column(db.String(4), nullable = False)
    roomType = db.Column(db.String(255), nullable = False)
    checkInTime = db.Column(db.DateTime, nullable = False)
    checkOutTime = db.Column(db.DateTime, nullable = False)
    numGuests = db.Column(db.Integer, nullable = False)
    numRooms = db.Column(db.Integer, nullable = False)
    paymentInfo = db.Column(db.String(20), nullable = False)
    paymentTotal = db.Column(db.Numeric(10,2), nullable = False)

    def __init__(self, bookingID, customerEmail, customerName, hotelID, roomType, checkInTime, checkOutTime, numGuests, numRooms, paymentInfo, paymentTotal):
        self.bookingID = bookingID
        self.customerEmail = customerEmail
        self.customerName = customerName
        self.hotelID = hotelID
        self.roomType = roomType
        self.checkInTime = checkInTime
        self.checkOutTime = checkOutTime
        self.numGuests = numGuests
        self.numRooms = numRooms
        self.paymentInfo = paymentInfo
        self.paymentTotal = paymentTotal


    def json(self):
        return {
            "bookingID" : self.bookingID,
            "customerEmail" : self.customerEmail,
            "customerName" : self.customerName,
            "hotelID" : self.hotelID,
            "roomType" : self.roomType,
            "checkInTime" : self.checkInTime.strftime("%Y-%m-%d %H:%M:%S"),
            "checkOutTime" : self.checkOutTime.strftime("%Y-%m-%d %H:%M:%S"),
            "numGuests" : self.numGuests,
            "numRooms" : self.numRooms,
            "paymentInfo" : self.paymentInfo,
            "paymentTotal" : str(self.paymentTotal)
        }


# health check
@app.route('/')
def health_check():
    host = request.host
    remote_addr = request.remote_addr
    return f"Welcome! host = {host}, remote_addr = {remote_addr}"

#get all bookings
@app.route("/booking")
def get_all():

    try:
        auth_token = request.headers['Authorization']
        if (auth_token != "yourSecretT0k4n"):
            return "Invalid authorization token.", 401

    except:
        return "Missing authorization token.", 401

    return jsonify({"bookings":[booking.json() for booking in Booking.query.all()]})


#get all bookings with customerEmail
@app.route("/booking/retrieve/email", methods =['POST'])
def get_by_email():

    try:
        auth_token = request.headers['Authorization']
        if (auth_token != "yourSecretT0k4n"):
            return "Invalid authorization token.", 401

    except:
        return "Missing authorization token.", 401

    try:
        data = request.get_json()
        customerEmail = data['customerEmail']
    except:
        return jsonify({"message":"Bad Request"}), 400

    customerEmailCheck = re.match(EMAIL_REGEX, customerEmail)

    if (customerEmailCheck):
        customerEmail = customerEmailCheck.group(0)
        return jsonify({"bookings":[booking.json() for booking in Booking.query.filter_by(customerEmail = customerEmail)]})

    return jsonify({"message":"Booking not found"}), 404


#get a specific booking
@app.route("/booking/retrieve/id", methods =['POST'])
def find_by_bookingID():

    try:
        auth_token = request.headers['Authorization']
        if (auth_token != "yourSecretT0k4n"):
            return "Invalid authorization token.", 401

    except:
        return "Missing authorization token.", 401

    try:
        data = request.get_json()
        bookingID = data['bookingID']
    except:
        return jsonify({"message":"Bad Request"}), 400

    booking = Booking.query.filter_by(bookingID = bookingID).first()
    if booking:
        return jsonify(booking.json())
    return jsonify({"message":"Booking not found"}), 404


#create a new Booking (Input parameters. customerEmail, customerName, hotelID, roomType, checkInTime, checkOutTime, numGuests, numRooms, paymentInfo, paymentTotal)
@app.route("/booking/new", methods =['POST'])
def create_booking():

    import datetime
    try:
        data = request.get_json()

        for key, value in data.items():
            if value == None:
                return jsonify({"message":f"{key} should not be NoneType."}), 400

        customerEmailCheck = re.match(EMAIL_REGEX, data['customerEmail'])

        if (customerEmailCheck == None):
            return jsonify({"message":"Please input a valid email address."}), 400

        new_booking = Booking(bookingID = None, **data)

    except:
        return jsonify({"message": "Please input a valid JSON."}), 400

    try:
        db.session.add(new_booking)
        db.session.commit()
        db.session.refresh(new_booking)

    except:
         return jsonify({"message":"An unknown error occurred while creating the booking."}), 500

    return jsonify(new_booking.json()), 201


@app.route("/booking", methods =['PUT'])
def update_booking(bookingID):

    try:
        auth_token = request.headers['Authorization']
        if (auth_token != "yourSecretT0k4n"):
            return "Invalid authorization token.", 401

    except:
        return "Missing authorization token.", 401


    if not (Booking.query.filter_by(bookingID = bookingID).first()):
        return jsonify({"message": "A booking with bookingID '{}' does not exist.".format(bookingID)}), 404

    try:

        customerEmailCheck = re.match(EMAIL_REGEX, request.json.get('customerEmail'))

        if (customerEmailCheck == None):
            return jsonify({"message":"Please input a valid email address."}), 400

        booking = Booking.query.filter_by(bookingID = bookingID).first()
        booking.bookingID = request.json.get('bookingID', booking.bookingID)
        booking.customerEmail = request.json.get('customerEmail', booking.customerEmail)
        booking.customerName = request.json.get('customerName', booking.customerName)
        booking.hotelID = request.json.get('hotelID', booking.hotelID)
        booking.roomType = request.json.get('roomType', booking.roomType)
        booking.checkInTime = request.json.get('checkInTime', booking.checkInTime)
        booking.checkOutTime = request.json.get('checkOutTime', booking.checkOutTime)
        booking.numGuests = request.json.get('numGuests', booking.numGuests)
        booking.numRooms = request.json.get('numRooms', booking.numRooms)
        booking.paymentInfo = request.json.get('paymentInfo', booking.paymentInfo)
        booking.paymentTotal = request.json.get('paymentTotal', booking.paymentTotal)

        db.session.commit()
        db.session.refresh(booking)

    except:
         return jsonify({"message":"An unknown error occurred updating the booking information."}), 500

    return jsonify(booking.json()), 200


#delete booking from database
# expected input: bookingID
@app.route("/booking",methods =['DELETE'])
def delete_booking(bookingID):

    try:
        auth_token = request.headers['Authorization']
        if (auth_token != "yourSecretT0k4n"):
            return "Invalid authorization token.", 401

    except:
        return "Missing authorization token.", 401


    if not (Booking.query.filter_by(bookingID = bookingID).first()):
        return jsonify({"message": "A booking with bookingID '{}' does not exist.".format(bookingID)}), 404

    try:
        booking = Booking.query.filter_by(bookingID = bookingID).first()
        db.session.delete(booking)
        db.session.commit()
    except:
        return jsonify({"message":"An unknown error occurred while deleting the booking."}), 500

    return jsonify({"message":f"Booking {bookingID} has been deleted successfully!"}),200


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)