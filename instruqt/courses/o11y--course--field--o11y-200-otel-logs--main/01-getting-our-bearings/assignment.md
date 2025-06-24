---
slug: getting-our-bearings
id: bnzyhcdxbkh1
type: challenge
title: Getting our bearings
notes:
- type: text
  contents: |-
    Observability tools are only as good as the fidelity of data on which
    they operate: the more common contextual data you can weave across your traces,
    metrics, and logs, the more powerful and accurate the resulting analysis.

    Application-specific context not only empowers ML and AI, it also makes it possible to quickly search
    for traces or logs relevant to a specific customer, session, or other market-specific
    attribute.

    The challenge, of course, is applying such attributes in a consistent,
    low-effort fashion, particularly as systems become more distributed and complex.

    *We are creating an Elastic cluster just for you! This process will take 2 to 3 minutes. When the  `Start` bottom appears in the bottom-right, click it to get started!*
tabs:
- id: 103y8fyabdvr
  title: Elasticsearch
  type: service
  hostname: kubernetes-vm
  path: /app/apm/service-map
  port: 30001
- id: sejr61ltskvd
  title: VS Code
  type: service
  hostname: host-1
  path: ?folder=/workspace/workshop
  port: 8080
- id: zopklqtzvxim
  title: Terminal (host-1)
  type: terminal
  hostname: host-1
difficulty: basic
timelimit: 600
enhanced_loading: null
---
To help us better appreciate how OpenTelemetry is forever changing observability, we will be working with an example stock trading system, comprised of several services and their dependencies, all instrumented using [OpenTelemetry](https://opentelemetry.io).

We will be working with a live Elasticsearch instance, displayed in the browser tab to the left. We are currently looking at Elastic's dynamically generated Service Map. It shows all of the services that comprise our system, and how they interact with one another.

![service-map.png](../assets/service-map.png)

Our trading system is composed of:
* `trader`: a python application that trades stocks on orders from customers
* `router`: a node.js application that routes committed trade records
* `recorder-java`: a Java application that records trades to a PostgreSQL database
* `notifier`: a .NET application that notifies an external system of completed trades

Finally, we have `monkey`, a python application we use for testing our system that makes periodic, automated trade requests on behalf of fictional customers.

> [!NOTE]
> You are welcome to explore each service and our APM solution by clicking on each service icon in the Service Map and selecting `Service Details`

When you are ready, click the `Next` button to continue.
