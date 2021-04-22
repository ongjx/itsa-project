import { makeStyles } from "@material-ui/core/styles";

const useStyles = makeStyles({
  // Room card component
  roomRoot: {
    display: "flex",
    justifyContent: "center",
  },
  roomDetails: {
    display: "flex",
    alignContent: "center",
    justifyContent: "center",
    flexDirection: "column",
  },
  roomContent: {
    flex: "1 0 auto",
    justifyContent: "center",
    alignContent: "center",
    width: 500,
  },
  roomCover: {
    width: 200,
    height: 140,
  },
  // Hotel Card Component
  hotelRoot: {
    maxWidth: 400,
    height: '100%',
    justifyContent: 'space-between',
    flexDirection: 'column',
    display: 'flex'
  },
  hotelMedia: {
    height: 140,
  },
  hotelContent: {
    flex: "1 0 auto",
    justifyContent: "center",
    alignContent: 'flex-end'
  },
  hotelText: {
    fontSize: '0.8em'
  }
});

export default useStyles;
