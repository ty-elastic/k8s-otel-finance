---
slug: generate-training
id: icjbgncknxen
type: challenge
title: Obtaining Training Data
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
We know there has been a rash of fraudulent transactions. Our customer service team has been diligently labelling those transactions as fraudulent as they are reported. Unfortunately, we don't know why those transactions are fraudulent; there are simply too many variables to track. This is, of course, an ideal application of a classification model.

To build a classification model, we first need data to train it against actual fraudulent data.

Setup Data Views
===
First, let's create a custom Index Alias in Elasticsearch which looks at _just_ the trade data we want to model and classify.

1. [button label="Elastic"](tab-0)
2. Copy and paste the following into the left-hand pane of `Developer Tools`
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
3. Execute the `POST` command by clicking on the triangle on the right-hand side of the first line of the command
4. Confirm the response
  ```nocopy
  {
    "acknowledged": true,
    "errors": false
  }
  ```
5. Copy and paste the following into the left-hand pane of Elasticsearch `Developer Tools`:
  ```
  POST kbn:/api/data_views/data_view
  {
    "data_view": {
      "name":"traces-trader",
      "title":"traces-trader",
      "timeFieldName":"@timestamp"
    }
  }
  ```
6. The response should indicate that a Data View was created

Obtaining training data
===
We will need a dataset of already classified transactions to train our model. Typically, this would come via your customer service team marking existing transactions as fraudulent as they are reported.

For our purposes, rather than include canned data already marked as fraudulent, we will put you in the mind of the criminal! You will be making a whole bunch of (secret) fraudulent transactions that we will pretend our customer service department finds (because they are reported by customers) and labels.

Let's put on our black hats and get to work!
1. Click on the [button label="Trader"](tab-1) tab
2. Click `Classification`
3. Decide what pattern your fraudulent transactions will follow. Maybe you only trade on certain days of the week or from certain regions? Or you only trade a certain number of certain stocks at certain prices? Come up with any combination you'd like! Leave `Classification` and `Data Source` fields as defaults, and be careful not to make your transactions _too_ specific or wide (e.g., don't limit trading to between just 5-10 shares of one stock, or leaving everything as default).
4. Click `SUBMIT`
5. Wait for the spinner to stop indicating that training data generation is complete (this could take a minute or two)

While you are waiting for the training data to be generated, consider taking a screen snapshot of your training configuration or writing down the parameters. You will need to reference this later to check how well our model is predicting fraud in new transactions.

Validate training data
===
Before we train our model, let's quickly check that the training data we just generated looks as expected:
1. [button label="Elastic"](tab-0)
2. Use the navigation pane to navigate to `Discover` and then select the `Discover` tab (and not `Logs Explorer`)
3. Set `Data view` to `traces-trader`
4. Set `Filter` to
  ```
  attributes.com.example.data_source : "training" and attributes.com.example.classification : "fraud"
  ```
5. Verify that the fraudulent training data we generated was recorded and labeled as expected. You can click on a row to examine attributes and ensure they match the pattern of fraudulent trades you generated.
