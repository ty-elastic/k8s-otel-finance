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
  path: /workspace/workshop/src/trader/app.py
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

You remember that your DevOps team recently instrumented your trading application with OpenTelemetry.




To help us better appreciate how OpenTelemetry is forever changing observability, we will be working with an example stock trading system, comprised of several services and their dependencies, all instrumented using [OpenTelemetry](https://opentelemetry.io).

We will be working with a live Elasticsearch instance, displayed in the browser tab to the left. We are currently looking at Elastic's dynamically generated Service Map. It shows all of the services that comprise our system, and how they interact with one another.


Our trading system is composed of:
* `trader`: a python application that trades stocks on orders from customers
* `router`: a node.js application that routes committed trade records
* `recorder-java`: a Java application that records trades to a PostgreSQL database
* `notifier`: a .NET application that notifies an external system of completed trades

Finally, we have `monkey`, a python application we use for testing our system that makes periodic, automated trade requests on behalf of fictional customers.

> [!NOTE]
> You are welcome to explore each service and our APM solution by clicking on each service icon in the Service Map and selecting `Service Details`

Adding span attributes
===
Among its many virtues, OpenTelemetry's support for common attributes which span across observability signals and your distributed services not only provides a solution to the aforementioned problems, but will also fuel the ML and AI based analysis we will consider in subsequent labs.

With only a very small investment in manual instrumentation (really, just a few lines of code!) on top of auto-instrumentation, every log and trace emitted by your distributed microservices can be tagged with common, application-specific metadata, like a `customer_id`.

`trader` is at the front of our user-driven call stack and seems like an ideal place to add a `customer_id` attribute. Let's do it!

`trader` is a simple python app built on the [flask](https://flask.palletsprojects.com/en/3.0.x/) web application framework. We are leveraging OpenTelemetry's rich library of [python auto-instrumentation](https://opentelemetry.io/docs/zero-code/python/) to generate spans when APIs are called without having to explicitly instrument service calls.


