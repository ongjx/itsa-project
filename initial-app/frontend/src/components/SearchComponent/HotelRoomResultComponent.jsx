import React, { useState, useEffect } from 'react';
import axios from 'axios'
import HotelCardComponent from "../Cards/HotelCardComponent"
import Grid from '@material-ui/core/Grid';
import { useHistory, useLocation } from 'react-router-dom';
import HotelInfoComponent from '../HotelInfoComponent/HotelInfoComponent';
import BackButtonComponent from '../BackButtonComponent';

const HotelRoomResultComponent = ({ callbackFn, hotelRoomId }) => {
    const history = useHistory();
    const state = useLocation();
    const [rooms, setRooms] = useState(state.state.rooms);
    const [prices, setPrices] = useState();

    useEffect(() => {
        sendWithRetry();
        rooms.sort((a,b) => a.searchRank < b.searchRank)
    }, []);

    const MAX_RETRY = 1;
    let currentRetry = 0;

    const errorHandler = () => {
        if (currentRetry < MAX_RETRY) {
            currentRetry++;
            setTimeout(() => {
                sendWithRetry();
            },3000)
        }
    }

    const sendWithRetry = () => {
        const destinationID = state.state.destinationId;
        const checkInDate = state.state.checkInDate;
        const checkOutDate = state.state.checkOutDate;
        const guest = state.state.guest;
        const fetchPriceURL = `https://api.ascendahotels.me/prices?destination_id=${destinationID}&checkin=${checkInDate}&checkout=${checkOutDate}&guests=${guest}`;
        axios.get(fetchPriceURL).then((res) => {
            const newPrices = res.data.hotels
            setPrices(newPrices)
            const isComplete = res.data.completed
            if (!isComplete) {
                errorHandler()
            }
        })
    }

    return (
        <>
            <BackButtonComponent pageBefore={state.pathname}/>
            {
                rooms && prices ?
                    <Grid container spacing={3} direction="row" justify="center">
                        {
                            prices && rooms ? rooms.map((item) => {
                                return (
                                    <Grid item xs={12} sm={6} md={4}>
                                        <HotelCardComponent hotelObject={item} priceObject={prices ? prices.filter(priceItem => priceItem.id === item.id) : []}/>
                                    </Grid>
                                )
                            }) : <></>
                        }
                    </Grid>
                    : <></>
            }

        </>
    )
}

export default HotelRoomResultComponent