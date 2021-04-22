import React, { useState, useEffect } from 'react';
import DestinationSearchComponent from './DestinationSearchComponent';
import axios from 'axios'
const SearchComponent = () => {
    const [selectedDestination, setSelectedDestination] = useState('');
    const [filteredHotels, setFilteredHotels] = useState([]);
    const [destinationsData, setDestinationsData] = useState();
    const [hotelsData, setHotelsData] = useState();

    const [cache, setCache] = useState();

    const retrieveDestinationData = () => {
        const cachedHits = localStorage.getItem("destinationData")
        let expiration = localStorage.getItem("expiration")
        let currTime = new Date().getTime()
        if (cachedHits && expiration && expiration > currTime) {
            setCache(cachedHits)
            getDestinations(cachedHits)
        } else {
            axios.get("https://api.ascendahotels.me/destinations").then(res => {
                const cache = JSON.stringify(res.data)
                localStorage.setItem("destinationData", cache)
                expiration = currTime + 86400000
                localStorage.setItem("expiration", expiration)
                setCache(cache)
                getDestinations(cache)
            })
        }
    }
    const getDestinations = (cache) => {
        const destinations = JSON.parse(cache).map((destinationObj => Object.entries(destinationObj).map((destination) => { return {destination: destination[0], id: destination[1]}}))).reduce((memo, it) => (memo.concat(it)), [])
        setDestinationsData(destinations)
    }

    const getHotels = (cache) => {
        const hotels = Object.values(JSON.parse(cache)).map(hotels => Object.entries(hotels.hotels).map(hotel => {return {id: hotels.primary_destination_id, hotel: hotel[0], hotel_id:hotel[1]}})).reduce((memo, it) => (memo.concat(it)), [])
        setHotelsData(hotels)
    }
    useEffect(() => {
        retrieveDestinationData()
    }, [])

    return (
        <div>
            <DestinationSearchComponent destinationsData={destinationsData} hotelsData={hotelsData}/>
        </div>
    )

}
export default SearchComponent