---
slug: otel
id: i8ndsv1bxpb0
type: challenge
title: Using OpenTelemetry to Record Transactions
tabs:
- id: lzoggpksfo6s
  title: Elastic
  type: service
  hostname: kubernetes-vm
  path: /app/apm/service-map?comparisonEnabled=true&rangeFrom=now-15m&rangeTo=now&offset=1d&kuery=data_stream.type%20:%22traces%22%20
  port: 30001
- id: eiupcnl0d2ad
  title: Trader Source Code
  type: code
  hostname: host-1
  path: /workspace/workshop/src/trader/variants/o11y--course--field--otel-200-fraud--main/app.py
- id: qtxb3kqiodpt
  title: Terminal (host-1)
  type: terminal
  hostname: host-1
  workdir: /workspace/workshop
- id: xogfz8xh7a7a
  title: Terminal (kubernetes-vm)
  type: terminal
  hostname: kubernetes-vm
difficulty: ""
timelimit: 0
enhanced_loading: null
---

Imagine you are in charge of an online stock trading application. The fraud protection team has made you aware of a recent wave of fraudulent transactions which appear to be happening across every region. These transactions are being flagged as they are reported, but the team hasn't been able to find any definitive pattern of fraudulent activity. You suspect there's a pattern; there are just too many variables in play to spot it by hand.

The team would love a way to automatically identify and label transactions that appear fraudulent _before_ customers call in to report them. Additionally, they would like to monitor the frequency of fraudulent transactions to determine if the rate is trending upward or downward.

You asked your data science team to estimate what it would take to develop, train, and deploy a classification model to identify fraudulent transactions. The work, not surprisingly, will take months. You unfortunately don't have that kind of time (or budget).

You remember that your DevOps team recently instrumented your trading application with OpenTelemetry. Since OTel is already recording every transaction to look for high latencies or failures, you are wondering if perhaps you can leverage that same data to look for fraud? You also remember something about Elastic having a built-in model for classification which can be easily trained and deployed.

Can these technologies be combined to quickly identify fraudulent transactions? Absolutely!

Getting our bearings
===

Let's have a look at the trace data from our trading system already coming into Elastic via OpenTelemetry to try to better understand how we could leverage it to determine fraud.

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
4. Scroll to the waterfall graph at the bottom

As you can see, OpenTelemetry is already capturing a transaction for every trade. By default, OpenTelemetry tags every transaction with obvious contextual stuff like `k8s.container.name`... Those attributes are less likely to indicate fraud. What we need are attributes that are specific to trading. Our trading application "knows" what is being traded; what if we added all of that trade-centric context to each transaction?

Adding span attributes
===

Among its many virtues, OpenTelemetry's support for common attributes which span across services and observability signals make it an incredibly powerful tool for Root Cause Analysis. Those same attributes, however, can also enable more advanced Machine Learning, as we will see in this lab.

Fortunately, OTel makes it _really_ easy to add custom attributes to spans.

Go ahead and click on the `trade` span in the waterfall graph. Note the `attributes.com.example.*` set of attributes. These sure look like good telltales to possibly determine if a transaction is fraudulent or not! How did they get there?

Our system is largely instrumented through OTel automatic instrumentation. To add those custom attributes, we used a little bit of manual instrumentation.
1. Click on the [button label="Trader Source Code"](tab-1) tab
2. Click on `app.py`
3. Scroll down to the `trade()` function
4. Note the set of calls to `trace.get_current_span().set_attribute()`. Each of these calls sets an attribute on the current span; easy!

That's it! We can still let OTels' automatic instrumentation do all the heavy lifting for us (e.g., instrumenting our server's entry points). By adding just a few lines of code, however, we've significantly increased the value of that trace data.

For example, by adding a customer identifier to our traces, SREs can now look at a specific customer flow when working through a customer-specific ticket!
1. Click on the [button label="Elastic"](tab-0) tab
2. Use the navigation pane to navigate to `Applications` > `Traces` > `Explorer`
3. Enter
  ```
  attributes.com.example.customer_id : "q.bert"
  ```
  in the Filter bar

In the next section, we will see how we can start to leverage these trade-specific attributes to help us predict fraudulent transactions.

