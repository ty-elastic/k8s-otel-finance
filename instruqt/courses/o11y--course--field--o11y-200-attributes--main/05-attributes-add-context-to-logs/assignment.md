---
slug: attributes-add-context-to-logs
id: bpmmy02kyyxb
type: challenge
title: Attributes add context to logs
notes:
- type: text
  contents: In this challenge, we will learn how to automatically add common attributes
    to our log lines
tabs:
- id: g3lshdcasiey
  title: Elasticsearch
  type: service
  hostname: kubernetes-vm
  path: /app/discover#/?_g=(filters:!(),refreshInterval:(pause:!t,value:60000),time:(from:now-15m,to:now))&_a=(columns:!(),dataSource:(dataViewId:'logs-*',type:dataView),filters:!(),hideChart:!f,interval:auto,query:(language:kuery,query:''),sort:!(!('@timestamp',desc)))
  port: 30001
- id: humujmeztiij
  title: VS Code
  type: service
  hostname: host-1
  path: ?folder=/workspace/workshop
  port: 8080
difficulty: basic
timelimit: 600
enhanced_loading: null
---
Attributes add context to logs!
===

So we've successfully added lots of rich attributes to our spans, but let's return to our log search:

1. Open the [button label="Elasticsearch"](tab-1) tab
2. Copy
    ```kql
    l.hall
    ```
    into the `Filter your data using KQL syntax` search bar toward the top of the Kibana window
3. Click on the refresh icon at the right of the time window picker
4. Click on the `Patterns` tab

Wouldn't it be great if we could also propagate our span attributes to our logs as well?

With common, automatically applied, attributes across your logs, you can focus your message text on **meaningful content that will help you perform RCA**, rather than manually adding context in a bespoke fashion that requires parsing and can obfuscate the actual message.

While most OpenTelemetry SDK distributions today include extensions to automatically apply attributes from baggage to spans, there does not currently exist extensions to automatically apply attributes from baggage to logs.

Fortunately, it is easy to author our own OpenTelemetry extensions!

# Python

Let's look at what I authored for Python:

1. Open the [button label="VS Code"](tab-1) tab
2. Navigate to `lib` / `python` / `baggage-log-record-processor` / `src` / `processor.py`
3. Note that we just follow the same basic pattern employed to apply baggage attributes to spans:
    ```python,nocopy
    def emit(
        self, log_data: logs.LogData
    ) -> None:
        if self._shutdown:
            # Processor is already shutdown, ignoring call
            return
        baggage = get_all_baggage(context.get_current())
        for key, value in baggage.items():
            if self._baggage_key_predicate(key):
                log_data.log_record.attributes[key] = value
    ```
    Essentially, for each log record to be emitted, copy all of the attributes from baggage and apply them to the log record as an attribute.

And let's add that to our Python app:

1. Open the [button label="VS Code"](tab-1) tab
2. Navigate to `src` / `trader` / `app.py`
3. Look for the following code line 33 inside the `init_otel()` function:
    ```python,nocopy
    def init_otel():
        trace.get_tracer_provider().add_span_processor(BaggageSpanProcessor(ALLOW_ALL_BAGGAGE_KEYS))
        tracer = trace.get_tracer("trader")

        if 'OTEL_PYTHON_LOGGING_AUTO_INSTRUMENTATION_ENABLED' in os.environ:
            print("enable otel logging")
    ```
4. Now let's attach the BaggageSpanProcessor to the default tracer provider by inserting the following line after `print("enable otel logging")`
    ```python
    logs.get_logger_provider().add_log_record_processor(BaggageLogRecordProcessor(ALLOW_ALL_BAGGAGE_KEYS))
    ```
5. You should now have:
    ```python,nocopy
    def init_otel():
        trace.get_tracer_provider().add_span_processor(BaggageSpanProcessor(ALLOW_ALL_BAGGAGE_KEYS))
        tracer = trace.get_tracer("trader")

        if 'OTEL_PYTHON_LOGGING_AUTO_INSTRUMENTATION_ENABLED' in os.environ:
            print("enable otel logging")
            logs.get_logger_provider().add_log_record_processor(BaggageLogRecordProcessor(ALLOW_ALL_BAGGAGE_KEYS))
    ```
6. Save the file (Command-S on Mac, Ctrl-S on Windows) or use the VS Code "hamburger" menu and select `File` / `Save`

# Java

We can craft a similar solution for Java:

1. Open the [button label="VS Code"](tab-1) tab
2. Navigate to `lib` / `java` / `src` / `main` / `java` / `com` / `example` / `baggage` / `logrecord` / `processor` / `BaggageLogRecordProcessor.java`
3. Note that we just follow the same basic pattern employed to apply baggage attributes to spans:
    ```java,nocopy
    public void onEmit(Context context, ReadWriteLogRecord logRecord) {
        // add baggage to log attributes
        Baggage baggage = Baggage.fromContext(context);
        baggage.forEach(
                (key, value) -> logRecord.setAttribute(
                        // add prefix to key to not override existing attributes
                        AttributeKey.stringKey(key),
                        value.getValue()));
    }
    ```
    Essentially, for each log record to be emitted, copy all of the attributes from baggage and apply them to the log record as an attribute.

And like the BaggageSpanProcessor, we can install it purely at the orchestration layer:

1. Open the [button label="VS Code"](tab-1) tab
2. Navigate to `src` / `recorder-java` / `Dockerfile`
3. Look for the Dockerfile directive around line 17:
    ```dockerfile,nocopy
    ENTRYPOINT ["java", \
    "-javaagent:elastic-otel-javaagent.jar", \
    "-Dotel.java.experimental.span-attributes.copy-from-baggage.include=*", \
    "-Dotel.java.experimental.span-stacktrace.min.duration=-1", \
    "-Dotel.inferred.spans.enabled=true", "-Dotel.inferred.spans.sampling.interval=1ms", "-Dotel.inferred.spans.min.duration=0ms", "-Dotel.inferred.spans.included.classes=com.example.*", \
    "-jar", "/recorder.jar"]
    ```
4. Add the following line after `"-Dotel.java.experimental.span-attributes.copy-from-baggage.include=*", \`:
    ```dockerfile
    "-Dotel.javaagent.extensions=opentelemetry-java-baggage-log-record-processor-all.jar", \
    ```
5. It should look like this:
    ```dockerfile
    ENTRYPOINT ["java", \
    "-javaagent:elastic-otel-javaagent.jar", \
    "-Dotel.java.experimental.span-attributes.copy-from-baggage.include=*", \
    "-Dotel.javaagent.extensions=opentelemetry-java-baggage-log-record-processor-all.jar", \
    "-Dotel.java.experimental.span-stacktrace.min.duration=-1", \
    "-Dotel.inferred.spans.enabled=true", "-Dotel.inferred.spans.sampling.interval=1ms", "-Dotel.inferred.spans.min.duration=0ms", "-Dotel.inferred.spans.included.classes=com.example.*", \
    "-jar", "/recorder.jar"]
    ```
6. Save the file (Command-S on Mac, Ctrl-S on Windows) or use the VS Code "hamburger" menu and select `File` / `Save`

We invoke my BaggageLogRecordProcessor extension via `-Dotel.java.experimental.span-attributes.copy-from-baggage.include=*`, which will hook into OpenTelemetry to automatically add attributes in baggage to any logs.

Let's test
===

1. Enter the following in the command line pane of VS Code to recompile:
    ```bash
    docker compose up -d --build
    ```

Wait for the build to complete....

1. Open the [button label="Elasticsearch"](tab-1) tab
2. Copy
    ```kql
    attributes.com.example.customer_id : "l.hall"
    ```
    into the `Filter your data using KQL syntax` search bar toward the top of the Kibana window
3. Click on the refresh icon at the right of the time picker

Nice! We now have a common set of attributes, added _once_ in our `trader` service, automatically propagated throughout our stack with minimal work!

> [!NOTE]
> In a subsequent lab, we will explore adding attributes from baggage to log lines where we cannot rely on the OpenTelemetry logging framework.

Summary
===

Behold: minimal effort for maximum effect. No more fragile regex expressions. Straightforward and definitive searching of traces and logs indexed by _your_ metadata. Imagine your SREs being able to quickly land definitively search for all logs or traces related to a given customer.