import logging

import time
import math

import requests

import multiprocessing
import math
import signal
import sys

TIMEOUT = 1
REGIONS = ['EU', 'EMEA', 'APAC']

def clear_latency(region):
    try:
        print(f'deleting latency for {region}')
        resp = requests.delete(f"http://monkey:9002/latency/region/{region}",
                                timeout=TIMEOUT)
        print(resp)
        return True
    except Exception as inst:
        return False

def create_latency(region, amount):
    try:
        print(f'generating latency for {region}')
        resp = requests.post(f"http://monkey:9002/latency/region/{region}/{amount}?latency_oneshot=false",
                                timeout=TIMEOUT,
                                params={'latency_oneshot': False})
        print(resp)
        return True
    except Exception as inst:
        print(inst)
        return False

def sigterm_handler(signum, frame):
        print("SIGTERM received. Initiating graceful shutdown...")
        for region in REGIONS:
            clear_latency(region)

        # Perform cleanup operations here
        sys.exit(0) # Exit the program after cleanup
signal.signal(signal.SIGTERM, sigterm_handler)


def cpu_intensive_task():
    stop = False
    try:
        while not stop:
            for i in range(1000000):
                try:
                    _ = math.sqrt(i) * math.sin(i) * math.log(i + 1)
                except KeyboardInterrupt:
                    print('exception received')
                    stop = True
                    break
    except Exception as inst:
        #print(inst)
        print("exception received.")

if __name__ == "__main__":
    num_cores = multiprocessing.cpu_count()
    processes = []

    for region in REGIONS:
        create_latency(region, 500)

    cpu_intensive_task()

    # try:
    #     for _ in range(num_cores):
    #         p = multiprocessing.Process(target=cpu_intensive_task)
    #         processes.append(p)
    #         p.start()

    #     for p in processes:
    #         p.join() # This will keep the main process waiting for child processes

    # except Exception as inst:
    #     #print(inst)
    #     print("exception received. Initiating graceful shutdown...")
    clear_latency('NA')
    clear_latency('LATAM')
    time.sleep(1)