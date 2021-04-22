import React, { useEffect, useState } from "react";
import { useHistory, useLocation } from "react-router-dom";
import { Button, Form } from "react-bootstrap";
import axios from "axios";
import BackButtonComponent from "../BackButtonComponent";
import Grid from "@material-ui/core/Grid";
import { css } from "@emotion/core";
import ClipLoader from "react-spinners/ClipLoader";

import RoomCardComponent from "../Cards/RoomCardComponent";

const override = css`
  display: block;
  margin: 0 auto;
  border-color: blue;
  radius: 3;
`;

const HotelInfoComponent = () => {
  const history = useHistory();
  const location = useLocation();
  const hotelObject = location.state.hotelObject;
  const isBookable = location.state.isBookable;
  const desc = hotelObject.description;

  const [rooms, setRooms] = useState();
  const [frequency, setFrequency] = useState();
  const [uniqueRooms, setUniqueRooms] = useState();
  const [loading, setLoading] = useState(true);
  const [color, setColor] = useState("#ffffff");

  const handleSubmit = (e) => {
    e.preventDefault();
    history.push({
      pathname: `/booking`,
      state: {
        hotelObject: hotelObject,
      },
    });
  };


  useEffect(() => {
    sendWithRetry()
  }, [])

  const getUniqueRooms = (rooms) => {
    const freq = rooms
      .map(({ description }) => description)
      .reduce((descriptions, description) => {
        const count = descriptions[description] || 0;
        descriptions[description] = count + 1;
        return descriptions;
      }, {});
    setFrequency(freq);
 
    const uniqueRooms = rooms.reduce(
      (acc, x) =>
        acc.concat(acc.find((y) => y.description === x.description) ? [] : [x]),
      []
    );
    setUniqueRooms(uniqueRooms);
  };

  const sendWithRetry = () => {
    const destinationID = location.state.destinationId;
    const checkInDate = location.state.checkInDate;
    const checkOutDate = location.state.checkOutDate;
    const guest = location.state.guest;
    const hotelID = hotelObject.id;
    const fetchPriceURL = `https://api.ascendahotels.me/hotels/prices?hotel=${hotelID}&destination_id=${destinationID}&checkin=${checkInDate}&checkout=${checkOutDate}&guest=${guest}`;
    axios.get(fetchPriceURL).then((res) => {
      const rooms = res.data.rooms;
      setRooms(rooms);
      getUniqueRooms(rooms);
      const isComplete = res.data.completed;
      setLoading(false);
    });
  };

  return (
    <>
      <BackButtonComponent pageBefore={location.state.pageBefore} />
      <Form onSubmit={handleSubmit}>
        <div style={{ paddingBottom: 30 }}>
          <h4>Hotel Overview</h4>
          <div dangerouslySetInnerHTML={{ __html: desc }} />
        </div>
        {loading || !uniqueRooms ? (
          <div style={{ paddingBottom: 30 }}>
            Loading
            <ClipLoader color={color} loading={true} css={override} size={40}/>
          </div>
        ) : (
          <></>
        )}
        {uniqueRooms && uniqueRooms.length > 0 ? (
          <Grid container spacing={3} direction="row" justify="center">
            {frequency ? (
              uniqueRooms.map((item) => {
                const image =
                  item.images.length > 0
                    ? item.images[0].url
                    : "https://cdn-s3.kaligo.com/assets/images/hotels_missing_images/hotel-room.jpg";
                return (
                  <Grid container direction="row" justify="center" item xs={12} sm={12} md={12}>
                    <RoomCardComponent
                      hotelObject={hotelObject}
                      roomObject={item}
                      image={image}
                      description={item.description}
                      price={item.price}
                      frequency={frequency[item.description]}
                    />
                  </Grid>
                );
              })
            ) : (
              <>
                <Button disabled="true" variant="outline-secondary" type="submit" style={{ width: "100%" }}>
                  Hotel Rooms Unavailable
                </Button>
              </>
            )}
          </Grid>
        ) : (
          <>
             <Button disabled="true" variant="outline-secondary" type="submit" style={{ width: "100%" }}>
              Hotel Room Unavailable
            </Button>
          </>
        )}
      </Form>
    </>
  );
};
export default HotelInfoComponent;
