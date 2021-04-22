import React, { useState, useEffect } from "react";
import { makeStyles } from "@material-ui/core/styles";
import Card from "@material-ui/core/Card";
import CardActionArea from "@material-ui/core/CardActionArea";
import CardActions from "@material-ui/core/CardActions";
import CardContent from "@material-ui/core/CardContent";
import CardMedia from "@material-ui/core/CardMedia";
import Button from "@material-ui/core/Button";
import Typography from "@material-ui/core/Typography";
import StarRatings from "react-star-ratings";
import { Link, NavLink, useHistory, useLocation } from "react-router-dom";
import BackButtonComponent from "../BackButtonComponent";
import useStyles from "../../utils/style";

const HotelCardComponent = ({ hotelObject, priceObject, allPrices }) => {
  const history = useHistory();
  const location = useLocation();
  const classes = useStyles();
  const destinationId = location.state.destinationId;
  const id = hotelObject.id;
  const name = hotelObject.name;
  const address = hotelObject.address;
  const image = hotelObject.cloudflare_image_url + `/${hotelObject.id}/i1.jpg`;
  const rating = hotelObject.rating;
  const [price, setPrice] = useState();
  const isBookable = price && price.length > 0 ? true : false;

  useEffect(() => {
    setPrice(priceObject);
  }, [priceObject]);

  const handleClick = () => {
    history.push({
      pathname: `/hotels/${id}`,
      state: {
        ...location.state,
        hotelObject: hotelObject,
        isBookable: isBookable,
        prices: allPrices,
      },
    });
  };
  return (
    <>
      <Card className={classes.hotelRoot}>
        <CardActionArea>
          <CardMedia
            className={classes.hotelMedia}
            image={
              "https://cdn-s3.kaligo.com/assets/images/hotels_missing_images/hotel-room.jpg"
            }
            title={name}
          >
            <CardMedia
              className={classes.hotelMedia}
              image={image}
              title={name}
            />
          </CardMedia>
          <CardContent>
            <Typography gutterBottom variant="h5" component="h2">
              <span className={classes.hotelText}>{name}</span>
            </Typography>

            <Typography gutterBottom variant="subtitle1">
              {address}
            </Typography>

            <Typography gutterBottom variant="subtitle1">
              {price ? (
                price.length > 0 ? (
                  <span style={{ color: 'blue' }}>${Math.round(price[0].price)}</span>
                ) : (
                  <span style={{ color: 'grey' }}>Last Room Already Sold</span>
                )
              ) : (
                <></>
              )}
            </Typography>

            <Typography
              gutterBottom
              variant="subtitle1"
              className={classes.hotelContent}
            >
              <StarRatings
                rating={rating}
                starRatedColor="orange"
                starDimension="20px"
                numberOfStars={5}
                name="rating"
              />
            </Typography>
          </CardContent>
        </CardActionArea>

        <CardActions>
          <div className={classes.hotelContent}>
            <Link
              to={{
                pathname: `/hotel-details`,
                state: {
                  ...location.state,
                  hotelObject: hotelObject,
                  isBookable: isBookable,
                  prices: allPrices,
                  pageBefore: location.pathname,
                },
              }}
            >
              View Hotel
            </Link>
          </div>
        </CardActions>
      </Card>
    </>
  );
};

export default HotelCardComponent;
