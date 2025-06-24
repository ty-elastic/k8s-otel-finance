---
slug: attributes-add-context-to-logs
id: 2hcp4ngcaqys
type: challenge
title: Attributes add context to logs
notes:
- type: text
  contents: In this challenge, we will learn how to automatically add common attributes
    to our log lines
tabs:
- id: ltrmvqela5wb
  title: Elasticsearch
  type: service
  hostname: kubernetes-vm
  path: /app/discover#/?_g=(filters:!(),refreshInterval:(pause:!t,value:60000),time:(from:now-15m,to:now))&_a=(columns:!(),dataSource:(dataViewId:'logs-*',type:dataView),filters:!(),hideChart:!f,interval:auto,query:(language:kuery,query:''),sort:!(!('@timestamp',desc)))
  port: 30001
- id: ho1zsqnqy1xb
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

# Java

And like the BaggageSpanProcessor, we can install it purely at the orchestration layer:

7. Navigate to `operator` / `values.yaml`
8. Scroll to the bottom and find the `instrumentation` config for `java`
9. Find
    ```yaml
    java:
        image: docker.elastic.co/observability/elastic-otel-javaagent:1.3.0
    ```
10. Immediately thereafter, add these lines:
    ```yaml
        env:
        - name: OTEL_JAVA_TEST_LOG_ATTRIBUTES_COPY_FROM_BAGGAGE_INCLUDE
            value: '*'
    ```
11. You should have:
    ```yaml
    apiVersion: opentelemetry.io/v1alpha1
    kind: Instrumentation
    metadata:
    name: elastic-instrumentation
    spec:
    java:
        image: docker.elastic.co/observability/elastic-otel-javaagent:1.3.0
        extensions:
        - image: us-central1-docker.pkg.dev/elastic-sa/tbekiares/baggage-processor
            dir: /extensions
        env:
        - name: OTEL_JAVA_TEST_SPAN_ATTRIBUTES_COPY_FROM_BAGGAGE_INCLUDE
            value: '*'
        - name: OTEL_JAVA_TEST_LOG_ATTRIBUTES_COPY_FROM_BAGGAGE_INCLUDE
            value: '*'
    ```
12. Save the file (Command-S on Mac, Ctrl-S on Windows) or use the VS Code "hamburger" menu and select `File` / `Save`
13. Redeploy the operator config by issuing the following:
    ```
    helm upgrade --install opentelemetry-kube-stack open-telemetry/opentelemetry-kube-stack   --namespace opentelemetry-operator-system   --values 'values.yaml'   --version '0.3.9'
    kubectl -n trading rollout restart deployment/recorder-java



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
