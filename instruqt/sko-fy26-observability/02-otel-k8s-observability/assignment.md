---
slug: otel-k8s-observability
id: fyssxfflpil8
type: challenge
title: Using OpenTelemetry to Observe Kubernetes
tabs:
- id: 6pgqntbj4jqg
  title: Elastic
  type: service
  hostname: kubernetes-vm
  path: /
  port: 30001
- id: ctgmema9bnrl
  title: Terminal
  type: terminal
  hostname: host-1
  workdir: /workspace/workshop
- id: pwqmbb1h5jrk
  title: Code
  type: code
  hostname: host-1
  path: /workspace/workshop/k8s
- id: kmkfnrdhph1d
  title: Control
  type: service
  hostname: host-1
  path: /index.html
  port: 9090
difficulty: ""
timelimit: 0
enhanced_loading: null
---
We have our application stack running on Kubernetes. Now let's observe it using Elastic!

## Install the OpenTelemetry Operator

With the advent of the OpenTelemetry Operator and related Helm chart, you can now easily deploy an entire observability signal collection package for Kubernetes, inclusive of:
* application traces, metrics, and logs
* infrastructure traces (nginx), metrics and logs
* application and infrastructure metrics

1. [button label="Elastic"](tab-0)
2. Click `Add Data` in bottom-left pane
3. Click `Kubernetes`
4. Click `OpenTelemetry (Full Observability)`
6. Click `Copy to clipboard` below `Add the OpenTelemetry repository to Helm`
7. [button label="Terminal"](tab-1)
8. Paste and run helm chart command
9. [button label="Elastic"](tab-0)
10. Click `Copy to clipboard` below `Install the OpenTelemetry Operator`
11. [button label="Terminal"](tab-1)
12. Paste and run k8s commands to install OTel operator

## Checking the Install

Let's use what we learned in the last challenge to be sure everything installed correctly. First, list out the available namespaces:
```bash,run
kubectl get namespaces
````
And get a list of pods running in the `opentelemetry-operator-system` namespace:
```bash,run
kubectl  -n opentelemetry-operator-system get pods
````

And let's look at the logs from the daemonset collector to see if it is exporting to Elasticsearch without error:
```bash
kubectl  -n opentelemetry-operator-system logs opentelemetry-kube-stack-gateway-collector-<xxxxxxxxxx-xxxxx>
````

## Checking Observability

Let's confirm what signals are coming into Elastic.

First, let's check for logs. Navigate to the [button label="Elastic"](tab-0) tab and click on `Observability` > `Discover`.

Next, let's check for infrastructure metrics. Navigate to the [button label="Elastic"](tab-0) tab and click on `Infrastructure` > `Hosts`.

Finally, let's check for application traces. Navigate to the [button label="Elastic"](tab-0) tab and click on `Applications` > `Service Inventory`. Note that there is not yet any APM data flowing in. Let's figure out what's up.

## Debugging APM

Let's describe one of our application pods... Specifically, the monkey pod:
```bash,run
kubectl -n k8sotel describe pod monkey
````
Look at the environment variables section; note that there are not yet any OTel environment variables loaded into the pod.

It turns out that after you apply the OTel Operator to your Kubernetes cluster, you need to restart all of your application services:
```bash,run
kubectl  -n k8sotel rollout restart deployment
````

Now let's wait for our monkey pod to restart:
```bash,run
kubectl -n k8sotel get pods
````

And once it has restarted, let's describe it agaibn:
```bash,run
kubectl -n k8sotel describe pod monkey
````

And now we can see OTel ENV vars being injected into the monkey pod. Let's check if we have APM data flowing in. Navigate to the [button label="Elastic"](tab-0) tab and click on `Applications` > `Service Inventory`. Ok cool, this is starting to look good. Click on the `trader` app and look at the `POST /trade/request` transaction. Scroll down to the bottom (trace samples) and look at the waterfall graph. Notice the broken trace. It looks like perhaps one of our applications is not being instrumented. Click on the `POST` span and look at `attributes.service.target.name`. Note that this `POST` is intended to target the `router` service, yet we don't see the `router` service in our Service Map.

Let's look at our `router` pod and see if we can figure out what's up.
```bash,run
kubectl -n k8sotel describe pod router
````

Huh. no OTel ENVs, even though the pod was restarted. Let's have a look at that deployment yaml. Click on the [button label="Code"](tab-2) button and examine the deployment yaml. Look at the deployment yaml for the `trader` service and compare it to the `router` service. Notice anything missing?

In order for the Operator to attach the correct APM agent, you need to apply an appropriate annotation to each pod. Note that the router pod is missing an annotation. Let's add it. In the Code editor, modify the router yaml to add the following annotation:

```
spec:
  template:
    metadata:
      annotations:
        instrumentation.opentelemetry.io/inject-nodejs: "opentelemetry-operator-system/elastic-instrumentation"
      ...
```
And then reapply the yaml:
```bash,run
kubectl apply -f k8s
```

Note that `router` was reconfigured:
```
deployment.apps/router configured
```

Wait for the `router` pod to restart:
```bash,run
kubectl -n k8sotel get pods
````

And once it has restarted, let's describe it again:
```bash,run
kubectl -n k8sotel describe pod router
````

And now it looks like our OTel ENVs are getting injected as expected. Let's check Elasticsearch. Navigate to the [button label="Elastic"](tab-0) tab and click on `Applications` > `Service Inventory`. Note that we can now see a full distributed trace, as expected!

