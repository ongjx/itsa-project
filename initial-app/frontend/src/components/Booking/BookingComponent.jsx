import React, { useState } from "react";
import { Button, Form } from "react-bootstrap";
import moment from "moment";
import axios from "axios";
import { useHistory, useLocation } from "react-router-dom";
import { CardElement, Elements } from "@stripe/react-stripe-js";
import {loadStripe} from '@stripe/stripe-js';
import Alert from '@material-ui/lab/Alert';
import cookie from 'react-cookies'

export default function BookingComponent({ bookingsdata }) {
  const defaultValues = {
    name: "",
    email: "",
    checkInDate: "",
    checkOutDate: "",
    numGuest: 1,
    numRoom: 1,
    checkInTime: "",
    checkOutTime: "",
    paymentInfo: "",
  };
  const [formValues, setFormValues] = useState(defaultValues);
  const [message, setMessage] = useState("");
  const [severity, setSeverity] = useState("")
  const stripePromise = loadStripe('pk_test_TYooMQauvdEDq54NiTphI7jx');
  const history = useHistory();
  const location = useLocation();
  const hotelObject = location.state.hotelObject;
  const roomObject = location.state.roomObject;
  const price = location.state.price;
  const desc = hotelObject.description;
  const token = cookie.load('Authorization')

  const checkInDate = location.state.checkInDate;
  const checkOutDate = location.state.checkOutDate;
  const guest = location.state.guest;
  const numroom= location.state.numroom;

  const handleChange = (e) => {
    var { name, value } = e.target;
    if (name == "numRoom" || name == "numGuest") {
      value = parseInt(value.split(" ")[0]);
    }
    if(name=="checkInTime" || name=="checkOutTime"){
      value = moment(value,'HH:mm:ss').format('HH:mm:ss')
    }
    setFormValues({
      ...formValues,
      [name]: value,
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const fetchURL = "https://api.ascendahotels.me/backend/booking/new";
    if(formValues.name=="" ||formValues.email==""||formValues.checkInTime==""||formValues.checkOutTime==""){
      setMessage("Please fill in the required fields")
      setSeverity("error")
    }else{
      try{
        await axios.post(fetchURL, {
          customerName: formValues.name,
          customerEmail: formValues.email,
          hotelID: hotelObject.id,
          roomType:roomObject.description,
          checkInTime:checkInDate + " " + formValues.checkInTime,
          checkOutTime:checkOutDate + " " + formValues.checkOutTime,
          numGuests:guest,
          numRooms: numroom,
          paymentInfo: "",
          paymentTotal: price
        }, { headers: {
          "Authorization": token
        }}).then((res) => {
          setMessage("Booking Success");
          setSeverity("success")
        });
      }catch(err){
        setMessage("error: please resend booking")
        setSeverity("error")
      }
    }
  };

  const minDate = moment(new Date()).format("YYYY-MM-DD");
  return (
    <div className="text-left p-4">
      <h2 className="mb-4">Booking for {hotelObject.name}</h2>
      <h5 className="mb-4">Room: {roomObject.description}</h5>
      <h5>Price: $ {price}</h5>
      <Form onSubmit={handleSubmit}>
        <Form.Group>
          <Form.Label>Name</Form.Label>
          <Form.Control
            name="name"
            type="text"
            placeholder="Enter name"
            onChange={handleChange}
          />
        </Form.Group>
        <Form.Group>
          <Form.Label>Email</Form.Label>
          <Form.Control
            name="email"
            type="email"
            placeholder="Enter email"
            onChange={handleChange}
          />
        </Form.Group>
        <Form.Group>
          <Form.Label>Check In Date:</Form.Label>
          <Form.Control
            name="checkInDate"
            type="date"
            min={minDate}
            value={checkInDate}
            editable={false}
          />
        </Form.Group>
        <Form.Group>
          <Form.Label>Check In Time:</Form.Label>
          <Form.Control
            name="checkInTime"
            type="time"
            onChange={handleChange}
          />
        </Form.Group>
        <Form.Group>
          <Form.Label>Check Out Date:</Form.Label>
          <Form.Control
            name="checkOutDate"
            type="date"
            min={minDate}
            value={checkOutDate}
            editable={false}
          />
        </Form.Group>
        <Form.Group>
          <Form.Label>Check Out Time:</Form.Label>
          <Form.Control
            name="checkOutTime"
            type="time"
            onChange={handleChange}
          />
        </Form.Group>
        <Form.Group controlId="formBasicCheckbox">
          <Form.Label>Number of Guests:</Form.Label>
          <Form.Control
            label="guests"
            name="numGuest"
            value = {guest}
            editable={false}
          >
          </Form.Control>
        </Form.Group>
        <Form.Group controlId="formBasicCheckbox">
          <Form.Label>Rooms:</Form.Label>
          <Form.Control
            label="rooms"
            name="numRoom"
            value = {numroom}
            editable={false}
          >
          </Form.Control>
        </Form.Group>
        <Form.Group controlId="payment">
          <Form.Label>Payment</Form.Label>
          <Elements stripe={stripePromise}>
            <CardElement
              options={{
                style: {
                  base: {
                    fontSize: "16px",
                    color: "#424770",
                    "::placeholder": {
                      color: "#aab7c4",
                    },
                  },
                  invalid: {
                    color: "#9e2146",
                  },
                },
              }}
            />
          </Elements>
        </Form.Group>
        {message? <Alert severity={severity}>{message}</Alert>: <></>}

        <Button
          variant="outline-primary"
          type="submit"
          style={{ width: "100%" }}
        >
          Confirm Booking
        </Button>
      </Form>
    </div>
  );
}
