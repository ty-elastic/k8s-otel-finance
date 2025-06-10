---
slug: life-before-attributes
id: jisxoxepbscp
type: challenge
title: Life before attributes
notes:
- type: text
  contents: In this challenge, we will consider the challenges of working with limited
    context while performing Root Cause Analysis of a reported issue
tabs:
- id: hsw0rkifti2m
  title: Elasticsearch
  type: service
  hostname: kubernetes-vm
  path: /app/discover#/?_g=(filters:!(),refreshInterval:(pause:!t,value:60000),time:(from:now-15m,to:now))&_a=(columns:!(),dataSource:(dataViewId:'logs-*',type:dataView),filters:!(),hideChart:!f,interval:auto,query:(language:kuery,query:''),sort:!(!('@timestamp',desc)))
  port: 30001
- id: rmoe0xntplg6
  title: VS Code
  type: service
  hostname: kubernetes-vm
  path: ?folder=/workspace
  port: 8080
difficulty: ""
timelimit: 600
enhanced_loading: null
---
Let's put ourselves in the shoes of an on-duty SRE. Assume you just were just assigned a ticket indicating that a customer with the id `l.hall` is experiencing problems.

Searching logs for user activity
===
Elastic is well known for its ability to search log records for arbitrary strings. This feature alone bring immense value to otherwise unstructured logs. Let's have a go at searching our application logs for lines related to `l.hall` using the tools available to us today.

Let's first just do a simplistic search for the string `l.hall` in any field within our logs:
1. Open the [button label="Elasticsearch"](tab-1) tab
2. Copy
    ```kql
    l.hall
    ```
    into the `Filter your data using KQL syntax` search bar toward the top of the Kibana window
3. Click on the refresh icon at the right of the time picker
4. Click on the `Patterns` tab

One immediate concern is that clearly customer id is expressed throughout our logs in unique ways. Already we see many patterns:
* `172.18.0.13 - - [18/Jan/2025 16:27:27] "POST /trade/request?symbol=BAA&day_of_week=Tu&customer_id=l.hall&latency_amount=0&region=LATAM&error_model=false&error_db=false&skew_market_factor=0&canary=false&data_source=monkey HTTP/1.1"`
* `trade committed for l.hall`
* `traded BAA on day Tu for l.hall`
* `trading ZYX for l.hall on Tu from LATAM with latency 0, error_model=false, error_db=false, skew_market_factor=0, canary=false`

While Elasticsearch can easily surface any log line containing `l.hall`, it does make clear the reliance SREs have on developers when searching for clues related to a given user or session: searchable attributes exist (or don't exist) and are named often at the whim of the developer. This search only returns log lines where the value of the `customer_id` variable was intentionally inserted into the log message by the developer. Without further development effort across functions and microservices, many log lines related to the processing of `l.hall` requests will not be returned because the developer did not think to proactively include `customer_id` in the log message.

# Parsing logs with ES|QL
Often, it is helpful to further perform some analysis on a given field. In this case, assume we want to graph customer id by region to see if `l.hall` is connecting to just one or to all of our regions.

Let's choose one of the patterns above and parse out customer id with ES|QL:
1. Click `Try ES|QL` in the upper taskbar
2. Copy
    ```es|ql
    FROM logs-*
    | GROK message """(?:^|[?&])customer_id=(?<customer_id>[^&]*).*region=(?<region>[^&]*)"""
    | WHERE customer_id is not null
    | STATS COUNT(customer_id) BY customer_id, region
    ```
    into the ES|QL input box (replacing whatever is there)
3. Click `Run`

This is incredibly powerful: we just taught Elasticsearch how to parse and make use of a new `customer_id` field. We were able to accomplish this "just in time" for search and analysis without resorting to ingest pipelines or other ingest-time parsing.

Like any string parsing exercise, however, this is fragile. If the pattern changes dramatically, this ES|QL will fail. And of course this GROK expression only covers one of the patterns in which customer id appears. Crafting ES|QL to accommodate all such patterns is of course possible, but more complex to write and maintain.

Ideally, of course, the log lines would all have a common, structured field like `customer_id`.

Searching traces for user activity
===
Conceptually, traces are an ideal way of tracking user activity through a system. They nicely capture execution flows across services, recording latency and outcomes at each step.

Let's look for traces related to `l.hall`:
1. Open the [button label="Elasticsearch"](tab-1) tab
2. Navigate to `Observability` / `APM` / `Traces`
3. Click on the `Explorer` tab
4. Copy
    ```kql
    l.hall
    ```
    into the `Filter your data using KQL syntax` search bar toward the top of the Kibana window
5. Click `Search`


This is actually surprisingly useful! We can obviously see and debug the database error that is plaguing `l.hall`.

Let's see how Elasticsearch was able to surface this transaction without explicit labels:
1. Click on the first row `POST`
2. Scroll down in the `Transaction details` flyout to find the `url` section
3. Note that `l.hall` appears in the `url.full` as a request parameter

Using the same text search available with logs, Elasticsearch found the parent `POST` transaction from the text embedded in the `url`, and then using `trace.id`, it was able to assemble all related spans, including the one that ultimately ended in failure (the database transaction).

# Why labels matter

While helpful, similar to logs, relying on arbitrary text strings is not ideal:
* in this case, we got lucky in that our customer id happens to be captured in the request arguments, and that the auto instrumentation for flask records the request arguments in an attribute
* there is no way for us to leverage Elastic's advanced OOTB analytics (which generally require discrete attributes) to help us quickly determine if this problem is happening only to `l.hall` or to all users.

1. Open the [button label="Elasticsearch"](tab-1) tab
2. Navigate to `Observability` / `APM` / `Service Inventory`
3. Click on the `Service Map` tab
4. Click on the `trader` service
5. Click on `Service Details`
5. Under `Transactions`, click on `POST /trade/request`
6. Scroll down to `Trace samples`, and click on `Failed transaction correlations`

Note that the results aren't particularly helpful in determining if this problem is specific to `l.hall` or more systemic.

Adding labels to spans
===

Most/all existing APM frameworks do offer the ability to add labels to your traces, with some caveats:
* adding labels generally means adding custom observability code to your service
* prior to OpenTelemetry, each vendor had their own API for adding labels, so adding labels meant vendor lock-in
* there was no way to automatically propagate labels through your services, so custom code would have to be added to each service in the calling chain leading to a similar problem as logs: each developer could name the `customer_id` label in a different fashion complicating search

Let's see how OpenTelemetry can help address these concerns!
