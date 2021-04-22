DROP DATABASE IF EXISTS `itsa`;

CREATE DATABASE `itsa` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE `itsa`;

CREATE TABLE booking (
    bookingID int NOT NULL AUTO_INCREMENT,
    customerEmail varchar (255) NOT NULL,
    customerName varchar(255) NOT NULL,
    hotelID varchar(4) NOT NULL,
    roomType varchar(255) NOT NULL,
    checkInTime DATETIME NOT NULL,
    checkOutTime DATETIME NOT NULL,
    numGuests int NOT NULL,
    numRooms int NOT NULL,
    paymentInfo varchar(20) NOT NULL,
    paymentTotal decimal(10,2) NOT NULL,
    PRIMARY KEY (bookingID)
);

CREATE TABLE user (
    userID int NOT NULL AUTO_INCREMENT,
    customerEmail varchar (250) NOT NULL UNIQUE,
    customerName varchar(255) NOT NULL,
    customerPassword varchar(255) NOT NULL,
    createdDate DATETIME NOT NULL,
    PRIMARY KEY (userID)
);