---
slug: otel
id: i8ndsv1bxpb0
type: challenge
title: Generating Tracing with Attributes using OpenTelemetry
tabs:
- id: lzoggpksfo6s
  title: Elastic
  type: service
  hostname: kubernetes-vm
  path: /app/apm/service-map
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

We will be leverarging OpenTelemetry to help us demonstrate how tracing can help train a classification model to idenitfy fraudulent transactions.

Imagine you are in charge of an online stock trading application. Your fraud team has made you aware of a recent wave of fradulent transactions which appears to be happening across every region. The fraud team has been able to identify these transactions, but it hasn't yet been able to find a pattern amongst the many variables associated with each transaction. Moreover, they would like to be alerted if it appears this wave of fraud is trending downward or upward.

The fraud team is working with your data scientists to try to develop and train a classification model, but the work will take at least a month. You don't have that kind of time.

You remember that your DevOps team recently instrumented your trading application with OpenTelemetry. Since OTel is already recording every transaction to look for high latency or failures, you are wondering if perhaps you can leverage that same data to look for fraud?

With OpenTelemetry and Elastic, you can!

# Getting Our Bearings

Let's have a look at the trace data already coming in via OpenTelemetry to try to better understand how we could leverage it to determine fraud.

We are currently looking at Elastic's dynamically generated Service Map. It shows all of the services that comprise our system, and how they interact with one another.

Our trading system is composed of:
* `trader`: a python application that trades stocks on orders from customers
* `router`: a node.js application that routes committed trade records
* `recorder-java`: a Java application that records trades to a PostgreSQL database
* `notifier`: a .NET application that notifies an external system of completed trades

Finally, we have `monkey`, a python application we use for testing our system that makes periodic, automated trade requests on behalf of fictional customers.

> [!NOTE]
> You are welcome to explore each service and our APM solution by clicking on each service icon in the Service Map and selecting `Service Details`

Let's have a look at the data we have available:
1. Click on the `trader` service
2. Click on `Service Details`
3. Click on the `Transactions` tab
4. Scroll to the bottom and click on `POST /trade/request`
5. Scroll to the waterfall graph at the bottom

As you can see, OpenTelemetry is already capturing every trade transaction. By default, it captures the obvious contextual stuff like `k8s.namespace.name`. But you're looking for the tells that would indicate a given transaction is fradulent. To capture those tells, we probably need to capture some industry-specific attributes with each transaction. Fortunately, OpenTelemetry makes that really easy! 

Adding span attributes
===

Among its many virtues, OpenTelemetry's support for common attributes which span across observability signals and your distributed services not only provides a solution to the aforementioned problems, but will also fuel the ML and AI based analysis we will utilize here.

Go ahead and click on the `trade` span in the waterfall graph. Note the `attributes.com.example.*` set of attributes. These sure look like good tells to possibly determine if a transaction is fraudulent or not. How did they get there?

Our system is largely instrumented through automatic instrumentation. To add those custom attributes, we used a little bit of manual instrumentation. 

Let's see what that looks like:
1. Click on the [button label="Trader Source Code"](tab-1) tab
2. Click on `app.py`
3. Scroll down to the `trade()` function
4. Note the set of calls to `trace.get_current_span().set_attribute()`. Each of these calls sets an attribute on the current span.

That's it. You can still leverage all of the magic of auto-instrumentation and just add a few lines of code to make it far more powerful.

While our intent is to use these attributes to help predict fraud, they also make it really easy to search your traces. Say for example you wanted to look at traces or logs for a specific customer:
1. Click on the [button label="Elastic"](tab-0) tab
2. Navigate to Applications > Traces > Explorer
3. Type
```
attributes.com.example.customer_id : "q.bert" 
``` in the Filter bar
4. Observe related traces
5. Click on logs and observe related logs

In this exercise, however, we will be leveraging these attributes to help us predict fraudulent transactions.

