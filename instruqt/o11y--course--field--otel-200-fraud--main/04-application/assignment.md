---
slug: application
id: ylynqfneshqn
type: challenge
title: Applying Our Model to Determine Fraud
tabs:
- id: xs7t9jhyoxnu
  title: Elastic
  type: service
  hostname: kubernetes-vm
  path: /app/ml/trained_models
  port: 30001
difficulty: ""
timelimit: 0
enhanced_loading: null
---

Apply our model
===

Now that we've built a model, let's deploy it and apply it against actual trades (not training data). We will be generating an Ingest Pipeline which can be applied as new records arrive (probably too processor intensive for high transaction rates) or in periodic batches (as we will demonstrate here).

1. On our Trained Models page, find the model `classifcation-*`
2. On the right hand side of row containing our model, click `...` to open a contextual menu and select `Deploy model`
3. Under `1. Details` select `Continue`
4. Under `2. Configure processor` select `Continue`
5. Under `3. Handle failures` select `Continue`
6. Under `4. Test (Optional)` select `Continue`
7. Under `5. Create` select `Create pipeline`

## Next steps

Under `Next steps`:
1. Open `Reindex with pipeline`
2. Set `Destination index name` to `classified_trades`
3. Enable `Create data view`
9. Click `Reindex`

Checking our accuracy
===

# Discover

1. In Elastic, navigate to `Discover`
2. We want to look specifically at _non-training_ data. To do that, set the `Filter` to
  ```
  attributes.com.example.data_source : "monkey" and ml.inference.classification.classification :"fraud"
  ```
3. Open a row and note that the attributes match the pattern of fraudulent transactions you previously generated (refer to that screen snapshot you took)

# Validate with Dashboard

1. In Elastic, navigate to `Dashboards` > `Fraudulent Transactions`
2. Validate that graphs match the pattern of fraudulent transactions you generated (refer to that screen snapshot you took)

Summary
===

Note that in less than an hour we were able to build, deploy, and validate a model which can successful predict fraudulent transactions based on the pattern seen in our hand-labeled data. 

Notably, you could retrain your model at any time. You can also have different labels, perhaps with a specific `fraud` label per incident. And as noted, you could either apply the classification in real-time as transactions are generated, or batch them hourly or nightly.
