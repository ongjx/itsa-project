import React, { useEffect, useState } from 'react';
import { useHistory, useLocation } from "react-router-dom";
import { makeStyles } from '@material-ui/core/styles';
import Table from '@material-ui/core/Table';
import TableBody from '@material-ui/core/TableBody';
import TableCell from '@material-ui/core/TableCell';
import TableContainer from '@material-ui/core/TableContainer';
import TableHead from '@material-ui/core/TableHead';
import TableRow from '@material-ui/core/TableRow';
import Paper from '@material-ui/core/Paper';
import axios from "axios";
import cookie from 'react-cookies'
const useStyles = makeStyles({
    table: {
      minWidth: 650,
    },
  });

export default  function ProfileComponent({ bookingsdata }) {
    const handleSubmit = (e) => {
        e.preventDefault();
    }
    const classes = useStyles();
    const history = useHistory();
    const location = useLocation();
    let email = "";
    if(!location.state){
      history.push({
        pathname: `/home`,
      })
    }else{
      const loginData = location.state.loginData;
      email = loginData.email;
    }

    const token = cookie.load('Authorization')
    const [bookingObj, setBookingObj] = useState();
    const [hotel, setHotel] = useState([]);

    useEffect(() => {
        const fetchURL = `https://api.ascendahotels.me/backend/booking/retrieve/email`;
        const data = {
          "customerEmail": email
        }
        axios.post(fetchURL, data, {headers: { 'Authorization': token }}).then((res) => {
            setBookingObj(res.data.bookings)

            res.data.bookings.map((row)=>{
              const hotelFetchURL = `https://api.ascendahotels.me/hotels/${row.hotelID}`;
              axios.get(hotelFetchURL).then((res) => {
                setHotel(hotel => ([...hotel, res.data.name]))
              })
            })
        })
    }, []);


    return (
        <div className='text-left p-4'>
            <h2 className='mb-4'>
                Profile
            </h2>
              <TableContainer component={Paper}>
              <Table className={classes.table} aria-label="simple table">
                <TableHead>
                  <TableRow>
                    <TableCell>Booking Id</TableCell>
                    <TableCell align="right">Hotel Name</TableCell>
                    <TableCell align="right">Room Type</TableCell>
                    <TableCell align="right">CheckIn DateTime</TableCell>
                    <TableCell align="right">CheckOut DateTime</TableCell>
                    <TableCell align="right">No. of Guests</TableCell>
                    <TableCell align="right">No. of Rooms</TableCell>
                    <TableCell align="right">Payment Total</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                    {bookingObj&&hotel&&hotel.length>0 && bookingObj.length>0? (bookingObj.map((row, i) => (
                    <TableRow key={row.name}>
                      <TableCell component="th" scope="row">
                        {row.bookingID}
                      </TableCell>
                      {/* {getHotel(row.hotelID)} */}
                      <TableCell align="right">{hotel? hotel[i]: <></>}</TableCell>
                      <TableCell align="right">{row.roomType}</TableCell>
                      <TableCell align="right">{row.checkInTime}</TableCell>
                      <TableCell align="right">{row.checkOutTime}</TableCell>
                      <TableCell align="right">{row.numGuests}</TableCell>
                      <TableCell align="right">{row.numRooms}</TableCell>
                      <TableCell align="right">${row.paymentTotal}</TableCell>
                    </TableRow>
                  ))): <></>}
                </TableBody>
              </Table>
            </TableContainer>
        </div>
    )
}

