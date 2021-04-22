import React, { useState } from 'react';
import axios from "axios";
import { Button, Form } from 'react-bootstrap';
import Alert from '@material-ui/lab/Alert';

const Register = ({ registerData }) => {
    const defaultValues = {
        email: "",
        password: "",
        cfmPassword: "",
    };
    const [formValues, setFormValues] = useState(defaultValues)
    const [message, setMessage] = useState("");
    const [severity, setSeverity] = useState("")

    const handleChange = (e) => {
        var { name, value } = e.target;

        setFormValues({
            ...formValues,
            [name]: value,
        });
    }

    const handleSubmit = async (e) => {
        e.preventDefault();
        setMessage("")
        setSeverity("")
        const fetchURL = "https://api.ascendahotels.me/backend/registration/new";
        if(formValues.password==""||formValues.cfmPassword==""||formValues.name==""||formValues.email==""){
            setMessage("Fill in required fields")
            setSeverity("error")
        }
        else if(formValues.password==formValues.cfmPassword){   
            try{
                await axios.post(fetchURL, {
                    customerName: formValues.name,
                    customerEmail: formValues.email,
                    customerPassword: formValues.password           
                }).then((res) => {
                    if(res.status==201){
                        setMessage("Registration success")
                        setSeverity("success")
                    }else{
                        throw new Error("user registered")
                    }
                });
            }catch(err){     
                setMessage("User has already been registered")
                setSeverity("error")
            }
        }else{
            setMessage("Passwords do not match")
            setSeverity("error")
        }
      };
    
    return (
        <div className='text-left p-4'>
            <h2 className='mb-4'>
                Register
            </h2>
            <Form onSubmit={handleSubmit}>

                <Form.Group controlId="name">
                    <Form.Label>Name</Form.Label>
                    <Form.Control type="text" name="name" placeholder="Name" onChange={handleChange} />
                </Form.Group>

                <Form.Group controlId="email">
                    <Form.Label>Email</Form.Label>
                    <Form.Control type="email" name="email" placeholder="Email" onChange={handleChange} />
                </Form.Group>

                <Form.Group controlId="password">
                    <Form.Label>Password</Form.Label>
                    <Form.Control type="password" name="password" placeholder="Password" onChange={handleChange} />
                </Form.Group>

                <Form.Group controlId="cfmPassword">
                    <Form.Label>Confirm Password</Form.Label>
                    <Form.Control type="password" name="cfmPassword" placeholder="Confirm Password" onChange={handleChange} />
                </Form.Group>

                <Button variant="primary" type="submit" style={{ 'width': '100%' }}>
                    Register
                </Button>
            </Form>
            {message? <Alert severity={severity}>{message}</Alert>: <></>}
        </div>
    )
}
export default Register