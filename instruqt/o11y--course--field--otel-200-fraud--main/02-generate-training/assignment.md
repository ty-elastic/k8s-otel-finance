---
slug: generate-training
id: icjbgncknxen
type: challenge
title: Generating Training Data
tabs:
- id: mym97vj0hmjv
  title: Elastic
  type: service
  hostname: kubernetes-vm
  path: /app/dev_tools#/console/shell
  port: 30001
- id: allim22boynn
  title: Trader
  type: service
  hostname: host-1
  path: /#/train
  port: 9090
difficulty: ""
timelimit: 0
enhanced_loading: null
---

Setup Data Views
===
First, let's create a custom Index Alias in Elasticsearch which looks at _just_ the trade data we want to model and classify.

1. [button label="Elastic"](tab-0)
2. Copy and paste the following into the left-hand pane of Elasticsearch Developer Tools
  ```
  POST /_aliases
  {
    "actions": [
      {
        "add": {
          "index": "traces-*",
          "alias": "traces-trader",
          "filter": {
            "bool": {
              "must": [
                {
                  "term": {
                    "service.name": "trader"
                  }
                },
                {
                  "exists": {
                    "field": "attributes.com.example.shares"
                  }
                }
              ]
            }
          }
        }
      }
    ]
  }
```
3. Execute the `POST` command by clicking on the triangle on the right side of the first line of the POST
4. Confirm the response
  ```nocopy
  {
    "acknowledged": true,
    "errors": false
  }
  ```
5. Copy and paste the following into the left-hand pane of Elasticsearch Developer Tools:
  ```
  POST kbn:/api/data_views/data_view
  {
    "data_view": {
      "name":"traces-trader",
      "title":"traces-trader"
    }
  }
  ```
6. Confirm the response

Generate training data
===

We know there has been a rash of fraudulent transactions. Our customer service team has been diligently labelling those transactions as fraudulent as they are reported. Unfortunately, we don't know why those transactions are fraudulent; there are simply too many variables to track.

To build a classification model, we first need data to train our model. This is a dataset of manually labeled transactions. Typically, this would come from your customer service team as fraudulent transactions are reported. 

For our purposes, rather than include canned data already marked as fraudulent, we will put you in the mind of the criminal! You will be making a whole bunch of (secret) fraudulent transactions that we will pretend our customer service department finds and labels as appropriate.

Let's put on our black hats and get to work!
1. Click on the [button label="Trader"](tab-1) tab
2. Click `Classification`
3. Decide what pattern your fraudulent transactions will follow. Maybe you only trade on certain days of the week or from certain regions? Or you only trade a certain number of certain stocks at certain prices? Come up with any combination you'd like! (leave `Classification` and `Data Source` fields as defaults)
4. Click `SUBMIT`
5. Wait for the spinner to indicate that training data generation is complete
6. While you are waiting, consider taking a screen snapshot of your training configuration so we can compare it later against the results of our classification

Validate Training Data
===

1. [button label="Elastic"](tab-0)
2. Use the navigation pane to navigate to `Discover`
3. Set `Data view` to `traces-trader`
4. Set `Filter` to
  ```
  attributes.com.example.data_source : "training" and attributes.com.example.classification : "fraud"
  ```
5. Verify that the fraudulent training data we generated was recorded and labeled as expected (you can click on a row to examine attributes and ensure they match the pattern of fraudulent trades you generated)
