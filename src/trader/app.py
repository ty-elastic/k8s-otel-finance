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
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1, x_host=1, x_prefix=1)

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
    trade_id = str(uuid.uuid4())

    customer_id = request.args.get('customer_id', default=None, type=str)

    day_of_week = request.args.get('day_of_week', default=None, type=str)
    if day_of_week is None:
        day_of_week = random.choice(['M', 'Tu', 'W', 'Th', 'F'])

    region = request.args.get('region', default="NA", type=str)

    symbol = request.args.get('symbol', default='ESTC', type=str)

    data_source = request.args.get('data_source', default='monkey', type=str)

    classification = request.args.get('classification', default=None, type=str)

    canary = request.args.get('canary', default="false", type=str)

    # forced errors
    latency_amount = request.args.get('latency_amount', default=0, type=float)
    latency_action = request.args.get('latency_action', default=None, type=str)
    error_model = request.args.get('error_model', default=False, type=conform_request_bool)
    error_db = request.args.get('error_db', default=False, type=conform_request_bool)
    error_db_service = request.args.get('error_db_service', default=None, type=str)

    skew_market_factor = request.args.get('skew_market_factor', default=0, type=int)

    return trade_id, customer_id, day_of_week, region, symbol, latency_amount, latency_action, error_model, error_db, error_db_service, skew_market_factor, canary, data_source, classification

def trade(*, region, trade_id, customer_id, symbol, day_of_week, shares, share_price, canary, action, error_db, data_source, classification, error_db_service=None):

    app.logger.info(f"trade requested for {symbol} on day {day_of_week}")

    response = {}
    response['id'] = trade_id
    response['symbol']= symbol
    
    params={'canary': canary, 'customer_id': customer_id, 'trade_id': trade_id, 'symbol': symbol, 'shares': shares, 'share_price': share_price, 'action': action}
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

    action = request.args.get('action', type=str)
    shares = request.args.get('shares', type=int)
    share_price = request.args.get('share_price', type=float)

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