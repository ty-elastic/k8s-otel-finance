import * as React from 'react';
import axios from "axios";

import { CircularProgress } from '@mui/material';
import Autocomplete from '@mui/material/Autocomplete';
import Grid from '@mui/material/Grid2';
import Button from '@mui/material/Button';
import Typography from '@mui/material/Typography';
import TextField from '@mui/material/TextField';
import Slider from '@mui/material/Slider';
import Box from '@mui/material/Box';

class Train extends React.Component {

    constructor(props) {
        super(props);

        this.options = {}
        this.options.day_of_week = [
            { value: 'M', label: 'Monday' },
            { value: 'Tu', label: 'Tuesday' },
            { value: 'W', label: 'Wednesday' },
            { value: 'Th', label: 'Thursday' },
            { value: 'F', label: 'Friday' },
        ];

        this.options.region = [
            { value: 'EMEA', label: 'EMEA' },
            { value: 'EU', label: 'EU' },
            { value: 'LATAM', label: 'LATAM' },
            { value: 'NA', label: 'NA' }
        ];

        this.options.action = [
            { value: 'Buy', label: 'Buy' },
            { value: 'Sell', label: 'Sell' },
            { value: 'Hold', label: 'Hold' }
        ];

        this.state = {
            day_of_week: this.options.day_of_week,
            region: this.options.region,
            symbol: '',
            action: this.options.action,
            shares: [-1, -1],
            share_price: [-1, -1],
            classification: 'fraud',
            data_source: 'training',
            loading: false
        };

        this.handleInputChange = this.handleInputChange.bind(this);
        this.handleSubmit = this.handleSubmit.bind(this);
    }

    handleInputChange(event) {
        const target = event.target;
        const value = target.type === 'checkbox' ? target.checked : target.value;
        const name = target.name;

        this.setState({
            [name]: value
        });
    }

    async handleSubmit(event) {
        event.preventDefault();

        try {
            let params = {}

            if (this.state.day_of_week.length > 0) {
                params.day_of_week = this.state.day_of_week.map(item => item.value)
            }
            if (this.state.region.length > 0) {
                params.region = this.state.region.map(item => item.value)
            }
            if (this.state.symbol.length > 0) {
                params.symbol = this.state.symbol
            }
            if (this.state.action.length > 0) {
                params.action = this.state.action.map(item => item.value)
            }
            if (this.state.shares[0] !== -1) {
                params.shares_min = this.state.shares[0]
            }
            if (this.state.shares[1] !== -1) {
                params.shares_max = this.state.shares[1]
            }
            if (this.state.share_price[0] !== -1) {
                params.share_price_min = this.state.share_price[0]
            }
            if (this.state.share_price[1] !== -1) {
                params.share_price_max = this.state.share_price[1]
            }
            if (this.state.data_source.length > 0) {
                params.data_source = this.state.data_source
            }

            console.log(params)

            this.setState({['loading']: true});
            await axios.post(`/monkey/train/${this.state.classification}`, params)
            this.setState({['loading']: false});
        } catch (err) {
            console.log(err.message)
        }
    }

    render() {
        return (
            <form onSubmit={this.handleSubmit}>
                <Grid container spacing={2}>

                    <Autocomplete
                        multiple
                        options={this.options.day_of_week}
                        name="day_of_week"
                        value={this.state.day_of_week}
                        onChange={(event, newValue) => {this.setState({['day_of_week']: newValue})}}
                        renderInput={(params) => (
                        <TextField
                            {...params}
                            variant="standard"
                            label="Day of Week"
                        />
                        )}
                    />
                    <Autocomplete
                        multiple
                        options={this.options.region}
                        name="region"
                        value={this.state.region}
                        onChange={(event, newValue) => {this.setState({['region']: newValue});}}
                        renderInput={(params) => (
                        <TextField
                            {...params}
                            variant="standard"
                            label="Region"
                        />
                        )}
                    />

                    <TextField
                        id="outlined-error"
                        name="symbol"
                        value={this.state.symbol}
                        onChange={this.handleInputChange}
                        label="Symbol"
                    />

                    <Autocomplete
                        multiple
                        options={this.options.action}
                        name="action"
                        value={this.state.action}
                        onChange={(event, newValue) => {this.setState({['action']: newValue});}}
                        renderInput={(params) => (
                        <TextField
                            {...params}
                            variant="standard"
                            label="Action"
                        />
                        )}
                    />


                    <Grid size={4}>
                        <Typography gutterBottom>Shares</Typography>
                        <Slider onChange={this.handleInputChange}
                            name="shares"
                            getAriaLabel={() => "Amount"}
                            getAriaValueText={() => this.state.shares}
                            valueLabelDisplay="on"
                            shiftStep={30}
                            step={10}
                            marks
                            min={-1}
                            max={1000}
                            value={this.state.shares}
                        />
                    </Grid>
                    <Grid size={4}>
                        <Typography gutterBottom>Share Price</Typography>
                        <Slider onChange={this.handleInputChange}
                            name="share_price"
                            getAriaLabel={() => "Price"}
                            getAriaValueText={() => this.state.share_price}
                            valueLabelDisplay="on"
                            shiftStep={30}
                            step={1}
                            marks
                            min={-1}
                            max={100}
                            value={this.state.share_price}
                        />
                    </Grid>
                    <TextField
                        id="outlined-error"
                        name="classification"
                        value={this.state.classification}
                        onChange={this.handleInputChange}
                        label="Classification"
                    />
                    <TextField
                        id="outlined-error"
                        name="data_source"
                        value={this.state.data_source}
                        onChange={this.handleInputChange}
                        label="Data Source"
                    />

                    <div>
                        {this.state.loading ? (
                        <CircularProgress />
                        ) : (
                        <Box width="100%"><Button variant="contained" data-transaction-name="Train" type="submit">Submit</Button></Box>
                        )}
                    </div>

                </Grid>
            </form >

        );
    }
}

export default Train;