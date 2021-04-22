import React, { useEffect, useState } from 'react';
import FuzzySearch from 'react-fuzzy';
import { Button, Form } from 'react-bootstrap';
import moment from 'moment'
import {  useHistory, useLocation } from 'react-router-dom';
import HotelCardComponent from "../Cards/HotelCardComponent"
import axios from 'axios'
export default  function DestinationSearchComponent({ destinationsData, hotelsData }) {
    let history = useHistory();
    let location = useLocation();
    const [destinations, setDestinations] = useState(destinationsData)
    const [hotels, setHotels] = useState(hotelsData)
    const [filteredHotels, setFilteredHotels] = useState([])
    useEffect(() => {
        setDestinations(destinationsData)
        setHotels(hotelsData)
    }, [destinationsData, hotelsData])

    const defaultValues = {
        destination: "",
        hotel: "",
        checkInDate: "",
        checkOutDate: "",
        numGuest: 1,
        numRoom: 1,
    };
    const [formValues, setFormValues] = useState(defaultValues)
    const [items, setItems] = useState()

    const setSelectedDestination = (selectedDestination) => {
        setFormValues({
            ...formValues,
            'destination': selectedDestination
        })
        // on select destination, filter hotels
        getFilteredHotels(selectedDestination.destination)
    }
    const getFilteredHotels = (destination) => {
        return axios.get(`https://api.ascendahotels.me/hotels?destination_id=${destination}`).then(res => {
            const data = res.data
            const hotels = data.map(hotel => {return {id: hotel.uid, hotel: hotel.hotel}})
            setFilteredHotels(hotels)
        })
    }

    const setSelectedHotel = (selectedHotel) => {
        setFormValues({
            ...formValues,
            'hotel': selectedHotel,
        });
    }
    const handleChange = (e) => {
        var { name, value } = e.target;

        if (name == 'numRoom' || name == 'numGuest') {
            value = parseInt(value.split(' ')[0])
        }

        setFormValues({
            ...formValues,
            [name]: value,
        });
    }

    const detectChange = (e, type) => { // handle change in destination value
        if (e.target.value === "" && type==='destination') {
            setFilteredHotels([]);
        }
        if (e.target.value === "" && type==='hotel'){
            setFormValues({
                ...formValues,
                'hotel': ''
            })
        }
    }

    const handleSubmit = (e) => {
        e.preventDefault();
        const destination = formValues.destination.destination
        const destinationId = formValues.destination.id
        const hotel = formValues.hotel.id
        const hotel_name = formValues.hotel.hotel
        const checkInDate = formValues.checkInDate
        const checkOutDate = formValues.checkOutDate
        const guest = formValues.numGuest
        const room = formValues.numRoom

        if (hotel && destination) {
            const fetchURL = `https://api.ascendahotels.me/hotels/${hotel}`;
            axios.get(fetchURL).then
            (res => {
                history.push({
                    pathname: `/hotel-details`,
                    state: {
                        pageBefore: '/',
                        hotelObject: res.data,
                        isBookable: true,
                        formValues:formValues,
                        destination: destination,
                        destinationId: destinationId,
                        checkInDate: checkInDate,
                        checkOutDate: checkOutDate,
                        guest: guest,
                        numroom: room
                    }
                })
            })
        }
        else if (hotel === undefined) { //only dest selected; no hotel was selected
            const fetchURL = `https://api.ascendahotels.me/hotels/info?destination_id=${destinationId}&checkin=${checkInDate}&checkout=${checkOutDate}&guest=${guest}`; // TODO: CHANGE THIS TO DYNAMIC URL
            axios.get(fetchURL).then(res => {
                setItems(res.data)
                history.push({
                    pathname: `/all-hotels`,
                    state: {
                        pageBefore: '/',
                        rooms: res.data,
                        destination: destination,
                        destinationId: destinationId,
                        checkInDate: checkInDate,
                        checkOutDate: checkOutDate,
                        guest: guest,
                        numroom: room
                    }
                })
            })
        }
    }
    const minDate = moment(new Date()).format("YYYY-MM-DD")
    return (
        <div className='text-left p-4'>
            <h2 className='mb-4'>
                Search for Hotels
            </h2>
            <Form onSubmit={handleSubmit}>
                <Form.Group controlId="destination"  onChange={(e) => detectChange(e,"destination")}>
                    <Form.Label>Destination</Form.Label>
                    <FuzzySearch
                        className='shadow-none' inputWrapperStyle={{ 'boxShadow': '' }} inputStyle={{ 'border': '1px solid #ced4da' }}
                        list={destinations ? destinations : []}
                        width={'100%'}
                        keys={['destination', 'id']}
                        keyForDisplayName={'destination'}
                        threshold={0.4}
                        placeholder={"Search Destination"}
                        onSelect={(newSelectedItem) => {
                            // Local state setter defined elsewhere
                            setSelectedDestination(newSelectedItem)
                        }}
                        shouldShowDropdownAtStart={false}
                    />
                </Form.Group>
                {
                    filteredHotels.length == 0 ? <></> :

                <Form.Group controlId="hotel" onChange={(e) => detectChange(e, "hotel")}>
                    <Form.Label>Hotel</Form.Label>
                    <FuzzySearch
                        className='shadow-none' inputWrapperStyle={{ 'boxShadow': '' }} inputStyle={{ 'border': '1px solid #ced4da' }}
                        list={filteredHotels}
                        width={'100%'}
                        keys={['id', 'hotel']}
                        keyForDisplayName={'hotel'}
                        threshold={0.4}
                        placeholder={"Search Hotel"}
                        onSelect={(newSelectedItem) => {
                            // Local state setter defined elsewhere
                            setSelectedHotel(newSelectedItem)
                        }}
                        shouldShowDropdownAtStart={true}
                    />
                </Form.Group>
                }
                <Form.Group>
                    <Form.Label>Check In Date</Form.Label>
                    <Form.Control name='checkInDate' type='date' min={minDate} onChange={handleChange} />
                </Form.Group>
                <Form.Group>
                    <Form.Label>Check Out Date</Form.Label>
                    <Form.Control name='checkOutDate' type='date' min={minDate} onChange={handleChange} />
                </Form.Group>
                <Form.Group controlId="formBasicCheckbox">
                    <Form.Label>Number of Guests</Form.Label>
                    <Form.Control as="select" label="guests" name='numGuest' onChange={handleChange}>
                        <option>1 Adult</option>
                        <option>2 Adult</option>
                        <option>3 Adult</option>
                        <option>4 Adult</option>
                        <option>5 Adult</option>
                    </Form.Control>
                </Form.Group>
                <Form.Group controlId="formBasicCheckbox">
                    <Form.Label>Rooms</Form.Label>
                    <Form.Control as="select" label="rooms" name='numRoom' onChange={handleChange}>
                        <option>1 Room</option>
                        <option>2 Room</option>
                        <option>3 Room</option>
                        <option>4 Room</option>
                        <option>5 Room</option>
                    </Form.Control>
                </Form.Group>
                <Button variant="outline-warning" type="submit" style={{ 'width': '100%' }}>
                    Check Availability
                </Button>

                <div className='mt-4'>
                    {/* <HotelCardComponent image="http://photos.hotelbeds.com/giata/bigger/06/069630/069630a_hb_ro_003.jpg" name="Hotel" price="$xx"></HotelCardComponent> */}
                </div>
            </Form>
        </div>
    )
}

