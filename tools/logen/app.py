from flask import Flask, request
from datetime import datetime, timezone, timedelta
import random
import ipaddress
import time
import logging
from threading import Thread
import yaml

import ua_generator
from ua_generator.options import Options
from ua_generator.data.version import VersionRange
from faker import Faker

app = Flask(__name__)
app.logger.setLevel(logging.INFO)

from opentelemetry._logs import LogRecord
from opentelemetry.exporter.otlp.proto.grpc._log_exporter import OTLPLogExporter
from opentelemetry.sdk._logs.export import ConsoleLogExporter
from opentelemetry.sdk._logs import LoggerProvider, LoggingHandler
from opentelemetry.sdk._logs.export import BatchLogRecordProcessor
from opentelemetry.sdk.resources import Resource

MAX_PROXY_LOGS_PER_SECOND = 1000
BACKLOG_SEND_DELAY = 0.00001

def make_logger(service_name, max_logs_per_second):
    logger_provider = LoggerProvider(
        resource=Resource.create(
            {
                "service.name": service_name
            }
        ),
    )
    otlp_exporter = OTLPLogExporter(endpoint="http://127.0.0.1:4317", insecure=True)
    processor = BatchLogRecordProcessor(
        otlp_exporter,
        schedule_delay_millis=1000,  # Export every 1 seconds
        max_queue_size=max_logs_per_second*3,
        max_export_batch_size=max_logs_per_second,
    )
    logger_provider.add_log_record_processor(processor)
    handler = LoggingHandler(level=logging.NOTSET, logger_provider=logger_provider)
    logger = logging.getLogger(service_name)
    logger.addHandler(handler)
    logger.setLevel(logging.INFO)
    return logger

request_error_per_customer = {}
stock_price = {}

NUM_CUSTOMERS_PER_REGION = 10

REGIONS = ['NA', 'LATAM', 'EU', 'EMEA', 'APAC']
SYMBOLS = ['ZVZZT', 'ZALM', 'ZYX', 'CBAZ', 'BAA', 'OELK']

URLS = ['/trade/request', '/trade/status']
SIZE = {
    '/trade/request': (205, 220),
    '/trade/status': (316, 340),
}

CLIENTIPS_PER_REGION = {
    'NA': '107.80.0.0/16',
    'LATAM': '186.189.224.0/20',
    'EU': '149.254.212.0/24',
    'EMEA': '102.65.16.0/20',
    'APAC': '101.136.0.0/14'
}

CHROME_VERSIONS = (125, 135)
ua_generator_options = Options()
ua_generator_options.version_ranges = {
    'chrome': VersionRange(CHROME_VERSIONS[0], CHROME_VERSIONS[1]),
}

CUSTOMERS_PER_REGION = {}
def generate_customers_per_region():
    fake = Faker()
    for region in REGIONS:
        CUSTOMERS_PER_REGION[region] = []
        for i in range(NUM_CUSTOMERS_PER_REGION):
            name = fake.unique.first_name().lower() + "." + fake.unique.last_name().lower()
            CUSTOMERS_PER_REGION[region].append(name)
generate_customers_per_region()

USERAGENTS_PER_USER = {}
def generate_useragent_per_user():
    for region in CUSTOMERS_PER_REGION.keys():
        for customer in CUSTOMERS_PER_REGION[region]:
            USERAGENTS_PER_USER[customer] = ua_generator.generate(options=ua_generator_options)
generate_useragent_per_user()

IP_ADDRESS_PER_USER = {}
def generate_ipaddress_per_user():
    for region in CUSTOMERS_PER_REGION.keys():
        for customer in CUSTOMERS_PER_REGION[region]:
            network = ipaddress.ip_network(CLIENTIPS_PER_REGION[region])
            ip_list = [str(ip) for ip in network]
            IP_ADDRESS_PER_USER[customer] = random.choice(ip_list)
generate_ipaddress_per_user()

def get_customers():
    customers = []
    for region in CUSTOMERS_PER_REGION:
        for customer in CUSTOMERS_PER_REGION[region]:
            customers.append(customer)
    return customers

def generate_nginx_line(*, ip, timestamp, method, url, protocol, status_code, size, ref_url, user_agent):
    line = f"{ip} - - [{timestamp}] \"{method} {url} {protocol}\" {status_code} {size} \"{ref_url}\" \"{user_agent}\"\n"
    return line

def generate_trader_line(*, symbol, price):
    line = f"current market share price for {symbol}: ${price}"
    return line

start_times = {}
def log(logger, name, timestamp, level, body):
    ct = timestamp.timestamp()
    if name not in start_times:
        start_times[name] = ct
    record = logger.makeRecord(name, 20, __file__, 0, body, None, None)
    record.created = ct
    record.msecs = ct * 1000
    record.relativeCreated = (record.created - start_times[name]) * 1000
    logger.handle(record)

def generate(*, name, generator_type, logger, start_timestamp, end_timestamp, interval_s, sleep_s):
    timestamp = start_timestamp
    while timestamp < end_timestamp if end_timestamp is not None else True:
        region = random.choice(REGIONS)
        customer_id = random.choice(CUSTOMERS_PER_REGION[region])
        url=random.choice(URLS)
        timestamp_str = timestamp.strftime("%d/%b/%Y:%H:%M:%S %z")
        symbol = random.choice(SYMBOLS)
        if symbol not in stock_price:
            stock_price[symbol] = random.randrange(10,200)
        stock_price[symbol] = stock_price[symbol] + random.randrange(-10,10)
        if stock_price[symbol] <= 10:
            stock_price[symbol] = 10

        if customer_id in request_error_per_customer:
            error_request = True if random.randint(0, 100) > (100-request_error_per_customer[customer_id]['amount']) else False
        else:
            error_request = False

        line = ""
        if generator_type == 'nginx':
            line = generate_nginx_line(ip=IP_ADDRESS_PER_USER[customer_id],
                                timestamp=timestamp_str,
                                method='POST',
                                url=url,
                                protocol='HTTP/1.1',
                                status_code=200 if error_request is False else 500,
                                size=random.randrange(SIZE[url][0],SIZE[url][1]),
                                ref_url='-',
                                user_agent=USERAGENTS_PER_USER[customer_id])
        elif generator_type == 'trader':
            line = generate_trader_line(symbol=symbol, price=stock_price[symbol])
        log(logger, name, timestamp, 'INFO', line)
        if sleep_s > 0:
            time.sleep(sleep_s)
        timestamp = timestamp + timedelta(seconds=interval_s)
    return timestamp

def bump_version_up_per_browser(*, browser, region):
    global request_error_per_customer
    for browser_version_range in ua_generator_options.version_ranges.keys():
        if browser_version_range == browser:
            last_max = ua_generator_options.version_ranges[browser].max_version.major
            ua_generator_options.version_ranges = {
                browser: VersionRange(last_max+1, last_max+1)
            }

    if region is not None:
        customers = CUSTOMERS_PER_REGION[region]
    else:
        customers = get_customers()
    for customer in customers:
        if USERAGENTS_PER_USER[customer].browser == browser:
            print(f'new ua for {browser}')
            new_ua = ua_generator.generate(browser=browser, options=ua_generator_options)
            USERAGENTS_PER_USER[customer] = new_ua
            print(f"start request error for customer {customer}")
            request_error_per_customer[customer] = {'amount': 100}

@app.post('/err/browser/<browser>')
def err_request_ua(browser):
    global request_error_per_customer
    region = request.args.get('region', default=None, type=str)

    bump_version_up_per_browser(browser=browser, region=region)
    return request_error_per_customer

def load_config():
    try:
        with open('config/o11y--course--field--100-logs-workflow--main.yaml', 'r') as file:
            data = yaml.safe_load(file)
            return data
    except FileNotFoundError:
        print("Error: 'config.yaml' not found.")
    except yaml.YAMLError as e:
        print(f"Error parsing YAML: {e}")
config = load_config()

def run_schedule(schedule):
    last_ts = None
    loggers = {}

    for item in schedule:
        print(f'{item}')
        if item['name'] not in loggers:
            loggers[item['name']] = make_logger(item['name'], item['logs_per_second'])

        if item['type'] == 'nginx' or item['type'] == 'trader':
            now = datetime.now(tz=timezone.utc)
            if item['backfill_start_minutes'] == 0:
                start = last_ts
            else:
                start = now - timedelta(minutes=item['backfill_start_minutes'])
            if 'backfill_stop_minutes' in item:
                stop = now - timedelta(minutes=item['backfill_stop_minutes'])
                send_delay = BACKLOG_SEND_DELAY
            else:
                stop = None
                send_delay = 1/item['logs_per_second']
            print(f'start={start},stop={stop},send_delay={send_delay}')
            last_ts = generate(name=item['name'], generator_type=item['type'], logger=loggers[item['name']], start_timestamp=start, 
                               end_timestamp=stop, interval_s=1/item['logs_per_second'], sleep_s=send_delay)

        elif item['type'] == 'request_errors':
            bump_version_up_per_browser(browser=item['browser'], region=item['region'])

def run_threads():
    for thread in config['threads']:
        Thread(target=run_schedule, args=[thread['schedule']], daemon=False).start()

Thread(target=run_threads, daemon=False).start()