import React, { useState } from 'react';
import { BrowserRouter as Router, Switch, Link, Route, useHistory } from "react-router-dom";
import { Button, Form } from 'react-bootstrap';
import axios from "axios";
import Alert from '@material-ui/lab/Alert';
import cookie from 'react-cookies'

const Login = ({ loginData }) => {
    const defaultValues = {
        email: "",
        password: ""
    };

    const [formValues, setFormValues] = useState(defaultValues)
    const history = useHistory();
    const [message, setMessage] = useState("");
    const [severity, setSeverity] = useState("");
    const [response, setResponse] = useState([])
    const handleChange = (e) => {
        var { name, value } = e.target;
        setFormValues({
            ...formValues,
            [name]: value,
        });
    }

    const expires = new Date()
    expires.setDate(Date.now() + 1000 * 60 * 60 * 24 * 14)

    const handleSubmit = async (e) => {
        e.preventDefault();
        setMessage("")
        setSeverity("")
        const fetchURL = "https://api.ascendahotels.me/backend/login";
        if(formValues.email=="" || formValues.password==""){
            setMessage("Please fill in email/password")
            setSeverity("error")
        }else{
            try{
                await axios.post(fetchURL, {
                    customerEmail: formValues.email,
                    customerPassword: formValues.password
                }).then((res) => {
                    setResponse(res)
                    setMessage("Login Success")
                    setSeverity("success")
                    history.push({
                        pathname: `/profile`,
                        state: {
                            loginData: formValues
                        }
                    })
                    cookie.save("Authorization", "yourSecretT0k4n", {
                        path: "/",
                        expires,
                        maxAge: 1000,
                        // domain: "https://*.ascendahotels.me",
                        // secure: true,
                        // httpOnly: true
                    })
                });
            }catch(err){
                console.log(err)
                setMessage("Wrong Credentials")
                setSeverity("error")
            }finally{
                if(response.length==0){
                    setMessage("Wrong Credentials")
                    setSeverity("error")
                }
            }
        }
    }
    return (
        <div className='text-left p-4'>
            <h2 className='mb-4'>
                Login
            </h2>
            <Form onSubmit={handleSubmit}>
                <Form.Group controlId="email">
                    <Form.Label>Email</Form.Label>
                    <Form.Control type="text" name="email" placeholder="email" onChange={handleChange} />
                </Form.Group>

                <Form.Group controlId="password">
                    <Form.Label>Password</Form.Label>
                    <Form.Control type="password" name="password" placeholder="Password" onChange={handleChange} />
                </Form.Group>

                <Button variant="primary" type="submit" style={{ 'width': '100%' }}>
                    Login
                </Button>

            </Form>
            {message? <Alert severity={severity}>{message}</Alert>: <></>}
        </div>
    )
}
export default Login