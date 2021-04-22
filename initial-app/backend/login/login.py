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

class User(db.Model):
    __tablename__ = 'user'

    userID = db.Column(db.Integer, primary_key = True, autoincrement = True)
    customerEmail = db.Column(db.String(250), unique = True, nullable = False)
    customerName = db.Column(db.String(255), nullable = False)
    customerPassword = db.Column(db.String(255), nullable = False)
    createdDate = db.Column(db.DateTime, nullable = False)
    
    def __init__(self, userID, customerEmail, customerName, customerPassword, createdDate):
        self.userID = userID
        self.customerEmail = customerEmail
        self.customerName = customerName
        self.customerPassword = customerPassword
        self.createdDate = createdDate


    def json(self):
        return {
            "userID" : self.userID,
            "customerEmail" : self.customerEmail,
            "customerName" : self.customerName,
            "customerPassword" : self.customerPassword,
            "createdDate" : self.createdDate.strftime("%Y-%m-%d %H:%M:%S")
        }    

# health check
@app.route('/')
def health_check():
    host = request.host
    remote_addr = request.remote_addr
    return f"Welcome! host = {host}, remote_addr = {remote_addr}"

#register user
@app.route("/login", methods = ['POST'])
def register():
    from passlib.hash import sha256_crypt
    import datetime

    try:
        data = request.get_json()

        for key, value in data.items():
            if value == None:
                return jsonify({"message":f"{key} should not be NoneType."}), 400

        customerEmailCheck = re.match(EMAIL_REGEX, data['customerEmail'])

        if (customerEmailCheck == None):
            return jsonify({"message":"Please input a valid email address."}), 400

        user = User.query.filter_by(customerEmail = data['customerEmail']).first()

        if (user and sha256_crypt.verify(data['customerPassword'], user.customerPassword)):
            return jsonify("Login successful."), 200, {'Authorization' : "yourSecretT0k4n"}

    except:
        return jsonify({"message":"An unknown error occurred while processing your login."}), 500

    return jsonify("Login failed."), 401


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002, debug=True)