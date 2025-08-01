from flask import Flask, request
import logging

import random
import os
import uuid
import math

import requests
from werkzeug.middleware.proxy_fix import ProxyFix

app = Flask(__name__)
app.logger.setLevel(logging.INFO)
app.logger.info(f"variant: default")

 # Apply ProxyFix to correctly handle X-Forwarded-For
# x_for=1 indicates that one proxy is setting the X-Forwarded-For header
# Adjust x_for based on the number of proxies in front of your Flask app
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=2)

import model

def conform_request_bool(value):
    return value.lower() == 'true'

@app.route('/health')
def health():
    return f"KERNEL OK"

@app.post('/reset')
def reset():
    model.reset_market_data()
    return None
    
def decode_common_args():
    params = request.get_json()

    trade_id = str(uuid.uuid4())

    customer_id = params.get('customer_id', None)
    if customer_id is None:
        raise Exception("malformatted customer_id", request.remote_addr)

    day_of_week = params.get('day_of_week', None)
    if day_of_week is None:
        day_of_week = random.choice(['M', 'Tu', 'W', 'Th', 'F'])
 
    region = params.get('region', "NA")

    symbol = params.get('symbol', 'ESTC')

    data_source = params.get('data_source', 'monkey')

    classification = params.get('classification', None)

    canary = params.get('canary', False)

    # forced errors
    latency_amount = params.get('latency_amount', 0)
    latency_action = params.get('latency_action', None)
    error_model = params.get('error_model', False)
    error_db = params.get('error_db', False)
    error_db_service = params.get('error_db_service', None)

    skew_market_factor = params.get('skew_market_factor', 0)

    return trade_id, customer_id, day_of_week, region, symbol, latency_amount, latency_action, error_model, error_db, error_db_service, skew_market_factor, canary, data_source, classification

def trade(*, region, trade_id, customer_id, symbol, day_of_week, shares, share_price, canary, action, error_db, data_source, classification, error_db_service=None):
    app.logger.info(f"trade requested for {symbol} on day {day_of_week}")

    response = {}
    response['id'] = trade_id
    response['symbol']= symbol
    
    params={'canary': "true" if canary else "false", 'customer_id': customer_id, 'trade_id': trade_id, 'symbol': symbol, 'shares': shares, 'share_price': share_price, 'action': action}
    print(params)
    if error_db is True:
        params['share_price'] = -share_price
        params['shares'] = -shares
        if error_db_service is not None:
            params['service'] = error_db_service
        
    trade_response = requests.post(f"http://{os.environ['ROUTER_HOST']}:9000/record", params=params)
    trade_response.raise_for_status()
    trade_response_json = trade_response.json()

    response['shares']= shares
    response['share_price']= share_price
    response['action']= action
    
    app.logger.info(f"traded {symbol} on day {day_of_week} for {customer_id}")
    
    return response
    
@app.post('/trade/force')
def trade_force():
    trade_id, customer_id, day_of_week, region, symbol, latency_amount, latency_action, error_model, error_db, error_db_service, skew_market_factor, canary, data_source, classification = decode_common_args()

    params = request.get_json()
    action = params.get('action')
    shares = params.get('shares')
    share_price = params.get('share_price')

    return trade (region=region, data_source=data_source, classification=classification, trade_id=trade_id, symbol=symbol, customer_id=customer_id, day_of_week=day_of_week, shares=shares, share_price=share_price, canary=canary, action=action, error_db=False)

@app.post('/trade/request')
def trade_request():
    trade_id, customer_id, day_of_week, region, symbol, latency_amount, latency_action, error_model, error_db, error_db_service, skew_market_factor, canary, data_source, classification = decode_common_args()
    
    action, shares, share_price = run_model(trade_id=trade_id, customer_id=customer_id, day_of_week=day_of_week, symbol=symbol, region=region,
                                                   error=error_model, latency_amount=latency_amount, latency_action=latency_action, skew_market_factor=skew_market_factor)
    
    return trade (region=region, data_source=data_source, classification=classification, trade_id=trade_id, symbol=symbol, customer_id=customer_id, day_of_week=day_of_week, shares=shares, share_price=share_price, canary=canary, action=action, error_db=error_db, error_db_service=error_db_service)

def run_model(*, trade_id, customer_id, day_of_week, region, symbol, error=False, latency_amount=0.0, latency_action=None, skew_market_factor=0):

    market_factor, share_price = model.sim_market_data(symbol=symbol, day_of_week=day_of_week, skew_market_factor=skew_market_factor)

    action, shares = model.sim_decide(error=error, region=region, latency_amount=latency_amount, latency_action=latency_action, symbol=symbol, market_factor=market_factor)

    return action, shares, share_price