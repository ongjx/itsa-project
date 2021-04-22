import React from 'react'
import {render, cleanup} from '@testing-library/react'
import App from './App'
import SearchComponent from "./components/SearchComponent/SearchComponent";
import Login from "./components/NavBar/Login";

 afterEach(cleanup)
 
 it('should take a snapshot of Search Component', () => {
    const { asFragment } = render(<Login />)
    
    expect(asFragment(<Login />)).toMatchSnapshot()
   })

