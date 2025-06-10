---
slug: adding-span-attributes
id: 6lw1ijyxwrhd
type: challenge
title: Adding span attributes
notes:
- type: text
  contents: In this challenge, we will learn how to add attributes to OpenTelemetry
    spans
tabs:
- id: yxlvx2h0yqzd
  title: Elasticsearch
  type: service
  hostname: kubernetes-vm
  path: /app/apm/service-map?comparisonEnabled=false&environment=ENVIRONMENT_ALL&rangeFrom=now-15m&rangeTo=now
  port: 30001
- id: fqrojah2vdgt
  title: VS Code
  type: service
  hostname: kubernetes-vm
  path: ?folder=/workspace
  port: 8080
difficulty: basic
timelimit: 600
enhanced_loading: null
---
Adding span attributes
===
Among its many virtues, OpenTelemetry's support for common attributes which span across observability signals and your distributed services not only provides a solution to the aforementioned problems, but will also fuel the ML and AI based analysis we will consider in subsequent labs.

With only a very small investment in manual instrumentation (really, just a few lines of code!) on top of auto-instrumentation, every log and trace emitted by your distributed microservices can be tagged with common, application-specific metadata, like a `customer_id`.

`trader` is at the front of our user-driven call stack and seems like an ideal place to add a `customer_id` attribute. Let's do it!

`trader` is a simple python app built on the [flask](https://flask.palletsprojects.com/en/3.0.x/) web application framework. We are leveraging OpenTelemetry's rich library of [python auto-instrumentation](https://opentelemetry.io/docs/zero-code/python/) to generate spans when APIs are called without having to explicitly instrument service calls.

So what needs to be added on top of OpenTelemetry's auto-instrumentation to add attributes to a span? Not much!

1. Open the [button label="VS Code"](tab-1) tab
2. Navigate to `src` / `trader` / `app.py`
3. Look for the python code around line 67:
    ```python,nocopy
    customer_id = request.args.get('customer_id', default=None, type=str)
    ```
4. Immediately thereafter, add this line to add customer_id as a span attribute:
    ```python
    trace.get_current_span().set_attribute(f"{ATTRIBUTE_PREFIX}.customer_id", customer_id)
    ```
    what does this do?
    * gets the current span (from context on the current thread)
    * sets customer_id (prefixed by `com.example` for best practice)
5. You should now have:
    ```python,nocopy
    customer_id = request.args.get('customer_id', default=None, type=str)
    trace.get_current_span().set_attribute(f"{ATTRIBUTE_PREFIX}.customer_id", customer_id)
    ```
6. Save the file (Command-S on Mac, Ctrl-S on Windows) or use the VS Code "hamburger" menu and select `File` / `Save`
7. Enter the following in the command line pane of VS Code to recompile:
    ```bash
    docker compose up -d --build
    ```

After issuing the rebuild command, wait for the build to complete...

Taking stock of our work
===

Let's see how far this gets us:

1. Open the [button label="Elasticsearch"](tab-1) tab
2. Navigate to `Observability` / `APM` / `Traces`
3. Click on the `Explorer` tab
4. Copy
    ```kql
    labels.com_example_customer_id : "l.hall"
    ```
    into the `Filter your data using KQL syntax` search bar toward the top of the Kibana window
5. Click `Search`
6. Click on the parent transaction `POST /trade/request` toward the top of the waterfall graph
7. A flyout panel will open on the right, showing all of the metadata associated with the span. Note the presence of `labels.com_example_customer_id`.

Ah-ha! This is clearly a much cleaner approach to definitively searching for customer id than relying on text matching.

8. Scroll down and click on the failed `SELECT trades.trades` child span
9. A flyout panel will open on the right, showing all of the metadata associated with the span. Note the lack of the label `labels.com_example_customer_id`.

Unfortunately, _this_ span (which covers interactions with the database) _isn't_ labeled with `com.example.customer_id`. We only labeled one span (`POST /trade/request`), and while that is ultimately a parent of this span, labels applied to the parent are not applied to their children.

# Leveraging Elastic's analytics

We should now be able to leverage Elastic's advanced analytics to help us determine the scope of this issue:

1. Open the [button label="Elasticsearch"](tab-1) tab
2. Navigate to `Observability` / `APM` / `Service Inventory`
3. Click on the `Service Map` tab
4. Click on the `trader` service
5. Click on `Service Details`
6. Under `Transactions`, click on `POST /trade/request`
7. Scroll down to `Trace samples`, and click on `Failed transaction correlations`

Nice - it appears all of our failed transactions are specific to `l.hall`! You can clearly start to see the value use of definitive labels brings to Elasticsearch.

What is good enough?
===

Is lack of definitive labels on spans problematic? Consider a few things:
* perhaps you want to analyze specific child spans (like `span.type : "db"`) for errors
* remember that we got "lucky" that our customer_id happened to be captured by auto-instrumentation

Also, don't forget the problems we encountered when searching logs (like missing log lines).

What if we could apply labels _once_ and have them automatically propagate through every related child span? Amazingly, this is possible with OpenTelemetry using Baggage!
