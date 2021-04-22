import * as React from "react"
import { AppBar, Toolbar, IconButton, List, ListItem, ListItemText, makeStyles, Container, Hidden } from "@material-ui/core"
import { Home } from "@material-ui/icons"
import { BrowserRouter as Router, Switch, Link, Route} from "react-router-dom";
import SideDrawer from "./SideDrawer"
import Register from './Register'
import Login from './Login'
const useStyles = makeStyles({
    navbarDisplayFlex: {
        display: `flex`,
        justifyContent: `space-between`
    },
    navDisplayFlex: {
      display: `flex`,
      justifyContent: `space-between`
    },
    linkText: {
      textDecoration: `none`,
      textTransform: `uppercase`,
      color: `white`
    }
  });

const NavBarComponent = () => {
    const classes = useStyles();

    const navLinks = [
        { title: `home`, path: `/home` },
        { title: `Register`, path: `/register` },
        { title: `Login`, path: `/login` },
        { title: `Demo Update`, path: `/DemoUpdate` },
    ]

    return (
        <>
        <AppBar position="static" className={'mb-5'}>
            <Toolbar>
                <Container maxWidth="lg" className={classes.navbarDisplayFlex}>
                    <IconButton edge="start" color="inherit" aria-label="home">
                        <Home fontSize="large" />
                    </IconButton>
                    <Hidden smDown>
                        <List component="nav" aria-labelledby="main navigation" className={classes.navDisplayFlex}>
                            {navLinks.map(({ title, path }) => (
                                <Link to={path} key={title} className={classes.linkText}>
                                    <ListItem button>
                                        <ListItemText primary={title} />
                                    </ListItem>
                                </Link>
                            ))}
                        </List>
                    </Hidden>
                    <Hidden mdUp>
                        <SideDrawer navLinks={navLinks} />
                    </Hidden>

                </Container>
            </Toolbar>
        </AppBar>
        </>
    )
  }
  export default NavBarComponent

