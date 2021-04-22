import React from "react";
import { FiChevronLeft } from "react-icons/fi";
import { useHistory, useLocation } from "react-router";
import { Link } from "react-router-dom";

const BackButtonComponent = ({pageBefore}) => {
  const history = useHistory();
  const location = useLocation();
  const handleBack = () => {
    window.history.back();
  };

  return (
    <>
      <Link
        className={"btn btn-large float-left"}
        to={{
          pathname: pageBefore,
          state: pageBefore === '/' ? { } : location.state,
        }}
      >
        <FiChevronLeft /> Back
      </Link>

      <div className={"clearfix"}></div>
    </>
  );
};

export default BackButtonComponent;
