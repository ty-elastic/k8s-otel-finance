---
slug: build-model
id: v4rd8yvxsunb
type: challenge
title: Build Model
tabs:
- id: mugxlwfaxeih
  title: Elastic
  type: service
  hostname: kubernetes-vm
  path: /app/ml/data_frame_analytics
  port: 30001
- id: 9anyjoeqxyi6
  title: Trader
  type: service
  hostname: host-1
  path: /#/train
  port: 9090
difficulty: ""
timelimit: 0
enhanced_loading: null
---

# Train Model

1. [button label="Elastic"](tab-0)
2. `Create data frame analytics job`
3. Select `data view` to `traces-trader`
4. Under `1. Configuration` select `Classification`
5. Under `1. Configuration` set `Query` to `attributes.com.example.data_source :"training"`
6. Under `1. Configuration` set `Dependent variable` to `attributes.com.example.classification`
7. Under `1. Configuration` uncheck all existing `Included Fields`
8. Under `1. Configuration` in `Search` enter `attributes.com.example`
9. Select the following fields:
* `attributes.com.example.action`
* `attributes.com.example.classification`
* `attributes.com.example.day_of_week`
* `attributes.com.example.share_price`
* `attributes.com.example.shares`
* `attributes.com.example.symbol`
10. Under `1. Configuration` set `Training Percent` to `100`
11. Under `1. Configuration` click `Continue`
12. Under `2. Additional options` set `Prediction field name` to `classification`
13. Under `2. Additional options` click `Continue`
14. Under `3. Job details` set `Job ID` to `classification`
15. Under `3. Job details` click `Continue`
16. Under `4. Validation` click `Continue`
17. Under `5. Create` click `Create`

# Validate

1. Navigation menu > Machine Learning > Data Frame Analytics > Jobs
2. Wait for progress `Phase 8/8`
2. On the right next to `classification` click `View`
3. Look at `Overall accuracy`

