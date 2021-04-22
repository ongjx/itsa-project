import React, { useState, useEffect } from "react";
import { useHistory, useLocation } from "react-router-dom";
import axios from "axios";
import HotelCardComponent from "../Cards/HotelCardComponent";
import Grid from "@material-ui/core/Grid";
import BackButtonComponent from "../BackButtonComponent";
import { css } from "@emotion/core";
import ClipLoader from "react-spinners/ClipLoader";

const override = css`
  display: block;
  margin: 0 auto;
  border-color: blue;
  radius: 3;
`;

export default function HotelRoomSearchComponent({ hotelsData }) {
  const history = useHistory();
  const state = useLocation();
  const [rooms, setRooms] = useState(state.state.rooms);
  const [prices, setPrices] = useState(state.state.prices);
  const [loading, setLoading] = useState(true);
  const [color, setColor] = useState("#ffffff");

  useEffect(() => {
    if (!rooms) {
      setRooms(state.state.rooms);
      if (rooms && rooms.length > 0) {
        rooms.sort((a, b) => a.searchRank < b.searchRank);
      }
    }
    if (!prices) {
      sendWithRetry();
    }else{
      setLoading(false)
    }
  }, []);

  const sendWithRetry = () => {
    const destinationID = state.state.destinationId;
    const checkInDate = state.state.checkInDate;
    const checkOutDate = state.state.checkOutDate;
    const guest = state.state.guest;
    const fetchPriceURL = `https://api.ascendahotels.me/prices?destination_id=${destinationID}&checkin=${checkInDate}&checkout=${checkOutDate}&guest=${guest}`;

    axios.get(fetchPriceURL).then((res) => {
      const newPrices = res.data.hotels;
      setPrices(newPrices);
      setLoading(false)
    });
  };

  return (
    <>
      <BackButtonComponent pageBefore={"/"} />
      {loading? (
          <div style={{ paddingBottom: 30 }}>
            Loading
            <ClipLoader color={color} loading={true} css={override} size={40}/>
          </div>
        ) : (
          <></>
        )}
      {rooms && prices ? (
        <Grid container spacing={3} direction="row" justify="center">
          {prices && rooms ? (
            rooms.map((item) => {
              return (
                <Grid item xs={12} sm={6} md={4}>
                  <HotelCardComponent
                    hotelObject={item}
                    priceObject={
                      prices
                        ? prices.filter((priceItem) => priceItem.id === item.id)
                        : []
                    }
                    allPrices={prices}
                  />
                </Grid>
              );
            })
          ) : (
            <></>
          )}
        </Grid>
      ) : (
        <></>
      )}
    </>
  );
}
