import React, { useState, useEffect } from "react";
import { makeStyles } from "@material-ui/core/styles";
import Card from "@material-ui/core/Card";
import CardActionArea from "@material-ui/core/CardActionArea";
import CardActions from "@material-ui/core/CardActions";
import CardContent from "@material-ui/core/CardContent";
import CardMedia from "@material-ui/core/CardMedia";
import Button from "@material-ui/core/Button";
import Typography from "@material-ui/core/Typography";
import useStyles from "../../utils/style";
import { Link, NavLink, useHistory, useLocation } from "react-router-dom";
import Grid from "@material-ui/core/Grid";

const RoomCardComponent = ({
  hotelObject,
  roomObject,
  description,
  image,
  price,
  frequency
}) => {
  const history = useHistory();
  const location = useLocation();
  const classes = useStyles();



  return (
    <>

      <Grid item xs={12} sm={8} md={8}>
        <Card className={classes.roomRoot}>
          <div>
            <CardMedia
              className={classes.roomCover}
              image={image}
              title={description}
            />
          </div>
          <div className={classes.roomDetails}>
            <CardContent className={classes.roomContent}>
              <Typography component="h5" variant="h5">
                {description}
              </Typography>
              <Typography variant="subtitle1" color="textSecondary">
                Price ${price}
              </Typography>
              <Typography variant="subtitle1" color="textSecondary">
                {
                 frequency>1? <>{frequency} Rooms Available</> : <>{frequency} Room Available</>
                }
              </Typography>
            </CardContent>
            <CardActions>
              <div className={classes.roomContent} >
                <Link
                  to={{
                    pathname: `/booking`,
                    state: {
                      ...location.state,
                      hotelObject: hotelObject,
                      roomObject: roomObject,
                      price: price,
                      pageBefore: location.pathname,
                    },
                  }}
                >
                  View Hotel
                </Link>
              </div>
            </CardActions>
          </div>
        </Card>
      </Grid>
    </>
  );
};

export default RoomCardComponent;
