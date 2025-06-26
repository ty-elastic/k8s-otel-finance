---
slug: kubernetes-101
id: irlr6wrssw1o
type: challenge
title: Kubernetes 101
tabs:
- id: fyq2hfsdifyw
  title: Terminal
  type: terminal
  hostname: host-1
- id: jywoe9acir9l
  title: Code
  type: code
  hostname: host-1
  path: /workspace/workshop/k8s
difficulty: ""
timelimit: 0
enhanced_loading: null
---
Let's learn some Kubernetes basics so we can navigate around a k8s cluster while deploying Elastic Agent or the OpenTelemetry Operator. To get started, click the [button label="Terminal"](tab-0) tab. This is a terminal into a VM with k3s (a small-scale Kubernetes distribution) installed.

## Check what's running
With Kubernetes, you typically partition your services into namespaces. Let's see if there are any namespaces already created on our cluster:
```bash,run
kubectl get namespaces
```
There are no explicit namespaces created at present, beyond the default namespace.

Kubernetes groups containers (running services or applications) into pods (groups of related containers). We can ask Kubernetes to list all the running pods for a given namespace:
```bash,run
kubectl -n default get pods
```
There are no pods currently running in the default namespace.

## Install an application stack
To install applications into Kubernetes, we use deployment yaml to describe our pods and services. Click on the [button label="Code"](tab-1) tab and look over the deployment yaml for our application stack. Then, let's deploy it to our Kubernetes cluster by running the following in the [button label="Terminal"](tab-0):
```bash,run
kubectl apply -f k8s
```

Now let's use what we learned above to check if our applications are running:
```bash,run
kubectl get namespaces
```
a-ha! We have a new namespace `trading`. Let's check for running pods:
```bash,run
kubectl -n trading get pods
```
Looks good!

## Debug an application stack
We can get logs for any pod listed above with command:
```bash
kubectl -n trading logs <pod name>
```
Pick a pod from the list above and get the current logs for that pod. You can retrieve logs from the last run of the pod (say it is crashing) by adding a `-p` flag to the command above.

Let's say we want to force one of our pods to restart. If you want to restart all of the active pods for a given deployment, you can do a rollout restart:
```bash
kubectl -n trading rollout restart deployment trader
```
If you want to delete a specific pod instance, you can delete it:
```bash
kubectl -n trading delete pod <pod name>
```
In either case, assuming its deployment yaml specified a minimum of 1 instance, Kubernetes will restart the pods for you. Let's check that it is restarting:
```bash,run
kubectl -n trading get pods
```

It is also often helpful to describe a pod, which will provide its current deployment yaml along with its status. Choose a pod from the list of pods you previously obtained and describe it:
```bash
kubectl -n trading describe pod <pod name>
```

Finally, say you wanted to check for connectivity from _inside_ a pod. You can generally always gain access to the bash shell inside a container/pod. In this case, let's get a shell inside our `monkey` pod; find the `monkey`'s pod name from the list of pods you previously obtained and execute the following:
```bash
kubectl -n trading exec -it <pod name> -- sh
```
You are now executing commands inside the `monkey` pod! You could now do something like:
```bash
curl http://proxy:9090
```
to validate connectivity from the `monkey` pod to the `proxy` pod.

## Congratulations!
Just knowing a few basic Kubernetes commands can go a long way when helping to debug a kubernetes system.
