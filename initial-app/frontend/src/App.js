import './App.css';
import AppRoutes from './AppRoutes';
import NavBarComponent from './components/NavBar/NavBarComponent';
import SearchComponent from './components/SearchComponent/SearchComponent';
import { BrowserRouter } from "react-router-dom";
function App() {
  return (
    <div className="App">
      <BrowserRouter>
      <NavBarComponent/>
      <div className='container'>
        <AppRoutes />
      </div>
      </BrowserRouter>
    </div>
  );
}

export default App;
