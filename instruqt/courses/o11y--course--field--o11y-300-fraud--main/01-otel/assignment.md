---
slug: otel
id: ffanqsfd5xxx
type: challenge
title: Using OpenTelemetry to Record Transactions
tabs:
- id: zvlkklx2ybeg
  title: Elastic
  type: service
  hostname: kubernetes-vm
  path: /app/apm/service-map?comparisonEnabled=true&rangeFrom=now-15m&rangeTo=now&offset=1d&kuery=data_stream.type%20:%22traces%22%20
  port: 30001
- id: bvvjm9dfwxvd
  title: Trader Source Code
  type: code
  hostname: host-1
  path: /workspace/workshop/src/trader/variants/o11y--course--field--o11y-300-fraud--main/app.py
- id: x38jsry9hpqw
  title: Terminal (host-1)
  type: terminal
  hostname: host-1
  workdir: /workspace/workshop
difficulty: ""
timelimit: 0
enhanced_loading: null
---
Imagine you are in charge of an online stock trading application. The fraud protection team has made you aware of a recent wave of fraudulent transactions. These transactions are being flagged as they are reported, but the team hasn't been able to find any definitive pattern of fraudulent activity. You suspect there's a pattern; there are just too many variables in play to spot it by hand.

You need a way to automatically identify and label transactions that appear fraudulent _before_ customers call in to report them. Additionally, you'd like to monitor the frequency of potentially fraudulent transactions to generate an alert when they are trending upward.

You know that identifying patterns in a complex, multi-variable system is exactly what Machine Learning does really well. You've asked your data science team to estimate what it would take to develop, train, and deploy a classification model to identify fraudulent transactions. The work, not surprisingly, will take months; you unfortunately don't have that kind of time.

You remember that your DevOps team recently instrumented your trading application with [OpenTelemetry](https://www.elastic.co/what-is/opentelemetry). Since OTel is already recording every transaction to identify high latency or failure, you are wondering if perhaps you can leverage that same data to look for fraud? You also recall hearing that Elastic has a [built-in model for classification](https://www.elastic.co/docs/explore-analyze/machine-learning/data-frame-analytics/ml-dfa-classification) which can be easily trained and deployed.

Can these technologies be combined to quickly identify fraudulent transactions?

Absolutely!

Getting our bearings
===
Let's have a look at the existing trace data to try to better understand how we could leverage it to determine fraud.

We are currently looking at Elastic's dynamically generated Service Map (you may have to click `Refresh` a few times for data to fully load). It depicts all of the services that comprise your system and how they interact with one another.

The trading system is composed of:
* `trader`: a python application that trades stocks on orders from customers
* `router`: a node.js application that routes committed trade records
* `recorder-java`: a Java application that records trades to a PostgreSQL database
* `notifier`: a .NET application that notifies an external system of completed trades

Finally, we have `monkey`, a python application we use for testing our system that makes periodic, automated trade requests on behalf of fictional customers.

Let's have a look at the data we have available to us:

1. Click on the `trader` service
2. Click on `Service Details`
3. Scroll down and under `Transactions` click `POST /trade/request`
4. Scroll down to the waterfall graph at the bottom

As you can see, OpenTelemetry is already capturing a transaction for every trade. By default, OpenTelemetry labels every transaction with obvious contextual stuff like `k8s.container.name`... Those standard attributes, however, aren't likely to be indicators of fraud. What we really need are attributes that are specific to trading. Our trading application, of course, "knows" the details of what is being traded; what if we added all of that trade-centric context to each transaction?

Adding span attributes
===
Among its many virtues, OpenTelemetry's support for common attributes which span across services and observability signals make it an incredibly powerful tool for Root Cause Analysis. Those same attributes, however, can also leveraged for custom Machine Learning, as we will see in this lab.

Go ahead and click on the `trade` span in the waterfall graph. Note the `attributes.com.example.*` set of attributes. These sure look like good telltales to possibly determine if a transaction is fraudulent or not! How did they get there?

Our system is largely instrumented through OTel automatic instrumentation. To add those custom attributes, we used a little bit of manual instrumentation.
1. Click on the [button label="Trader Source Code"](tab-1) tab
2. Click on `app.py`
3. Scroll down to the `trade()` function
4. Note the set of calls to `trace.get_current_span().set_attribute()`. Each of these calls sets an attribute on the current span from data otherwise known to our `trader` service.

That's it! We can still leverage OTel automatic instrumentation to instrument our application's ingress and egress functions. By adding just a few lines of code, however, we've significantly increased the value of that trace data.

For example, by adding a customer identifier to our traces, SREs can now observe specific customer flows when working through tickets:
1. Click on the [button label="Elastic"](tab-0) tab
2. Use the navigation pane to navigate to `Applications` > `Traces` > `Explorer`
3. Enter the following into the Filter box:
  ```
  attributes.com.example.customer_id : "q.bert"
  ```

Note how quickly and easily we can find traces for a specific customer without having to rely on manual correlation (e.g., what node serviced this customer's request at what time).

We can also look at our spans using Discover
1. Navigate to the [button label="Elastic"](tab-0) tab
2. Use the navigation pane to navigate to `Discover` and then select the `Discover` tab (and not `Logs Explorer`)
3. Click `Try ES|QL`
4. Enter the following ES|QL:
  ```
  FROM traces-trader |
  LIMIT 100 |
  KEEP attributes.com.example.trade_id, attributes.com.example.action, attributes.com.example.day_of_week, attributes.com.example.region, attributes.com.example.share_price, attributes.com.example.shares, attributes.com.example.symbol
  ```

In the next section, we will see how we can start to leverage these trade-specific attributes to help us predict fraudulent transactions.
