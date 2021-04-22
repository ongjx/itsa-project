import { Switch, Route, Redirect, withRouter, BrowserRouter } from "react-router-dom";
import Login from "./components/NavBar/Login";
import Register from "./components/NavBar/Register";
import HotelInfoComponent from "./components/HotelInfoComponent/HotelInfoComponent";
import SearchComponent from "./components/SearchComponent/SearchComponent";
import HotelRoomResultComponent from "./components/SearchComponent/HotelRoomResultComponent";
import BookingComponent from "./components/Booking/BookingComponent";
import ProfileComponent from "./components/Profile/ProfileComponent";
import HotelRoomSearchComponent from "./components/SearchComponent/HotelRoomSearchComponent";
const AppRoutes = () => {
  return (
    <Switch>
      <Route path="/home">
        <SearchComponent />
      </Route>
      <Route path="/register">
        <Register />
      </Route>
      <Route path="/login">
        <Login />
      </Route>
      <Route path="/booking">
        <BookingComponent />
      </Route>
      <Route path="/profile">
        <ProfileComponent />
      </Route>
      <Route exact path="/all-hotels" component={withRouter(HotelRoomSearchComponent)} />
      <Route exact path="/hotel-details" component={withRouter(HotelInfoComponent)} />
      <Route path={`/view-rooms`}>
        <HotelRoomResultComponent />
      </Route>
      <Route path={`/hotels/:hotelId`}>
        <HotelInfoComponent />
      </Route>
      <Route path="/">
        <SearchComponent />
      </Route>
    </Switch>
  );
};

export default AppRoutes;
