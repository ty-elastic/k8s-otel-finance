---
slug: rbac
id: nxo4fxk0dray
type: challenge
title: Protecting Data with RBAC
tabs:
- id: qxodixi0jlll
  title: Elasticsearch
  type: service
  hostname: kubernetes-vm
  path: /app/streams
  port: 30001
- id: poj3poztpezq
  title: Terminal
  type: terminal
  hostname: kubernetes-vm
difficulty: basic
timelimit: 600
enhanced_loading: false
---

1. Navigate to `Management` > `Stack Management` > `Security` > `Roles`
2. Select `limited_viewer`
3. For Indices `/~(([.]|ilm-history-).*)/` click `Grant access to specific fields`
4. Under `Defined fields` set `client.geo.*`
5. Click `Update role`


