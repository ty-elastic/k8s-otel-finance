---
slug: kubernetes-101
id: kwwk9vdhawdi
type: challenge
title: Kubernetes 101
tabs:
- id: vdpidfyzbd6y
  title: Terminal
  type: terminal
  hostname: host-1
- id: y8yyocoor5yi
  title: Code
  type: code
  hostname: host-1
  path: /workspace/workshop/k8s
difficulty: ""
timelimit: 0
enhanced_loading: null
---
Let's learn some Kubernetes basics so we can navigate around a customer's k8s cluster while deploying Elastic Agent or the OpenTelemetry Operator. To get started, click the [button label="Terminal"](tab-0) tab. This is a terminal into a VM with k3s (a small-scale Kubernetes distribution) installed.

## Check what's running
With Kubernetes, you typically partition your services into namespaces. Let's see if there are any namespaces already created on our cluster:
```bash,run
kubectl get namespaces
````
There are no explicit namespaces created at present, beyond the default namespace.

Kubernetes groups containers (running services or applications) into pods (groups of related containers). We can ask Kubernetes to list all the running pods for a given namespace:
```bash,run
kubectl -n default get pods
````
There are no pods currently running in the default namespace.

## Install an application stack
To install applications into Kubernetes, we use deployment yaml to describe our pods and services. Click on the [button label="Code"](tab-1) tab and look over the deployment yaml for our application stack. Then, let's deploy it to our Kubernetes cluster by running the following in the [button label="Terminal"](tab-0):
```bash,run
kubectl apply -f k8s
````

Now let's use what we learned above to check if our applications are running:
```bash,run
kubectl get namespaces
````
a-ha! We have a new namespace `k8sotel`. Let's check for running pods:
```bash,run
kubectl -n k8sotel get pods
````
Looks good!

## Debug an application stack
We can get logs for any pod listed above with command:
```bash
kubectl -n k8sotel logs <pod name>
````
Pick a pod from the list above and get the current logs for that pod. You can retrieve logs from the last run of the pod (say it is crashing) by adding a `-p` flag to the command above.

Let's say we want to force one of our pods to restart. There are several ways to do this with Kubernetes, but perhaps the easiest way is to just delete the pod. Its deployment yaml told Kubernetes to always keep 1 copy running, so we can be sure Kubernetes will create a replacement:
```bash
kubectl -n k8sotel delete pod <pod name>
````
and let's check that it is restarting:
```bash,run
kubectl -n k8sotel get pods
````

It is also often helpful to describe a pod, which will provide its current deployment yaml along with its status. Choose a pod from the list of pods you previously obtained and describe it:
```bash
kubectl -n k8sotel describe pod <pod name>
```

Finally, say you wanted to check for connectivity from _inside_ a pod. You can generally always gain access to the bash shell inside a container/pod. In this case, let's get a shell inside our `monkey` pod; find the `monkey`'s pod name from the list of pods you previously obtained and execute the following:
```bash
kubectl -n k8sotel exec -it <pod name> -- sh
````
You are now executing commands inside the `monkey` pod! You could now do something like:
```bash
curl http://proxy:9090
````
to validate connectivity from the `monkey` pod to the `proxy` pod.

## Congratulations!
Just knowing a few basic Kubernetes commands can go a long way when helping to debug a customer system. In the next challenge, we will rely on knowledge of some of these commands to help install and debug installation of the Elastic Kubernetes OpenTelemetry operator.
