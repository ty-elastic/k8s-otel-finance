
import Market from './components/Market'
import Trade from './components/Trade'
import Error from './components/Error'
import Test from './components/Test'
import Train from './components/Train'

import TraderAppBar from './components/TraderAppBar'

import './App.css';
import { v4 as uuidv4 } from 'uuid';
import axios from "axios";
import { Route, NavLink, HashRouter, BrowserRouter, Routes } from "react-router-dom";

import * as React from 'react';
import Button from '@mui/material/Button';

// set sessionId on OTel baggage
var sessionId = uuidv4();
axios.defaults.headers.common['baggage'] = `com.example.session_id=${sessionId}`;

function App() {
  return (
    <HashRouter>
      <div className="App">
        <TraderAppBar />
        <div className="content">
          <Routes>
            <Route exact path="/" element={<Trade />} />
            <Route path="/market" element={<Market />} />
            <Route path="/error" element={<Error />} />
            <Route path="/test" element={<Test />} />
            <Route path="/train" element={<Train />} />
          </Routes>
        </div>
      </div>
    </HashRouter>
  );
}

export default App;