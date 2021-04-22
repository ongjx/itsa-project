variable "site_bucket_name" {
  description = "S3 site bucket name"
  type        = string
  default = "ascendahotelsbucket"
}

variable "endpoint" {
  description = "Endpoint url"
  type        = string
  default = "ascendahotels.me"
}

variable "domain_name" {
  description = "Domain name"
  type        = string
  default = "ascendahotels.me"
}

#############################

variable "bucket_name" {
  description = "S3 data bucket name"
  type        = string
  default = "ascenda-bucket-data"
}

variable "destination" {
   default = "./functions/getDestinations"
}

variable "hotels" {
   default = "./functions/getHotels"
}

variable "prices" {
   default = "./functions/getPrices"
}

variable "roomprices" {
   default = "./functions/getRoomPrices"
}

variable "hotelinfo" {
   default = "./functions/getHotelInfo"
}

variable "processdata" {
  default = "./functions/processData"
}

variable "hotelsbydestination" {
   default = "./functions/getHotelsByDestination"
}

variable "processdatazip" {
   default = "./functions/processData/main.zip"
}
variable "destzip" {
   default = "./functions/getDestinations/main.zip"
}
variable "hotelszip" {
   default = "./functions/getHotels/main.zip"
}
variable "priceszip" {
   default = "./functions/getPrices/main.zip"
}
variable "roompriceszip" {
   default = "./functions/getRoomPrices/main.zip"
}
variable "hotelinfozip" {
   default = "./functions/getHotelInfo/main.zip"
}

variable "hotelsbydestzip" {
      default = "./functions/getHotelsByDestination/main.zip"
}

variable "sql_script" {
      default = <<-EOT
      DROP DATABASE IF EXISTS itsa;

      CREATE DATABASE itsa CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

      USE itsa;

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
      EOT
}