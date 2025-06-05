---
slug: build-model
id: v4rd8yvxsunb
type: challenge
title: Building a Model
tabs:
- id: mugxlwfaxeih
  title: Elastic
  type: service
  hostname: kubernetes-vm
  path: /app/ml/data_frame_analytics
  port: 30001
difficulty: ""
timelimit: 0
enhanced_loading: null
---

Model training
===

We will now train a classification model on the training data you just generated.

1. In Elastic, select `Create data frame analytics job`
3. Set the `source data view` to `traces-trader`

## 1. Configuration

Under `1. Configuration`, set the following:
1. Select `Classification` as the job type
2. We want to train our model on the training data we just generated, so set `Query` to
  ```
  attributes.com.example.data_source : "training"
  ```
3. We've classified our training data as `fraudulent` and `unclassified`. We want our model to be able to predict this classification for future trades, so let's tell it which field contains our classification. Set the `Dependent variable` to:
  ```
  attributes.com.example.classification
  ```
4. We now need to tell the model what specific attributes might be useful to predict a pattern of fraudulent activity. First, uncheck all existing `Included Fields` by clicking the checkbox in the upper-left corner
5. Now let's look specifically at those attributes we manually added to the span. In `Included Fields` > `Search` enter
  ```
  attributes.com.example
  ```
6. Let's train our model to look at the specific fields we think might be influences in predicting `classification`. Select the following fields:
  * `attributes.com.example.action`
  * `attributes.com.example.classification`
  * `attributes.com.example.day_of_week`
  * `attributes.com.example.share_price`
  * `attributes.com.example.shares`
  * `attributes.com.example.symbol`
7. Since we've filtered to just the training data we generated, we can set `Training Percent` to `100`
8. Click `Continue`

## 2. Additional options

1. Set `Prediction field name` to
  ```
  classification
  ```
2. Click `Continue`

## 3. Job details

1. Set `Job ID` to
  ```
  classification
  ```
2. Click `Continue`

## 4. Validation

1. Click `Continue`

## 5. Create

1. Click `Create`

Measuring our model's accuracy
===

1. In Elastic, use the navigation page to navigate to `Machine Learning` > `Data Frame Analytics` > `Jobs`
2. Wait for progress to read `Phase 8/8`
3. On the right side of the `classifcation` job, click `View`
4. Look at `Overall accuracy`; this shows how well the model would have predicted the actual `classification`

