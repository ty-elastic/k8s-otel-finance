---
slug: generate-training
id: icjbgncknxen
type: challenge
title: Generate Training
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
- id: grqljfnk8gzv
  title: Terminal (host-1)
  type: terminal
  hostname: host-1
  workdir: /workspace/workshop
- id: cfmasc9oibxh
  title: Terminal (kubernetes-vm)
  type: terminal
  hostname: kubernetes-vm
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
3. Execute the `POST` command by clicking on the play triangle on the right side of the first line of the POST
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

Generate Training Data
===

We know there have been a rash of fraudulent transactions. Our customer service team has been diligently labeleling those transactions as fraudulent when they are reported. Unfortunately, we don't know why those transactions are fraudulent; there are simply too many variables to track.

To build a classification model, we need what is called training data. This is a dataset of manually labeled transactions. Normally, this would come from data collected by our customer service team as fraudulent transactions are reported. Rather than include canned data already marked as fraudulent, we will put you in the mind of the criminal. You will be making a whole bunch of fraudulent transactions that we will pretend our customer service department finds and reports.

Let's get to work!

1. Click on the [button label="Trader"](tab-1) tab
2. Click `Classification`
3. Decide what pattern your fraudulent transactions will follow. Maybe you generally only trade on certain days of the week or from certain regions. Or you only trade certain stocks at certain prices. Come up with any combination you'd like. (leave `Classification` and `Data Source` fields as is)
4. Click `SUBMIT`
5. Wait for spinner to complete

# Validate Training Data

1. [button label="Elastic"](tab-0)
2. Navigation menu > Discover
3. Set `Data view` to `traces-trader`
4. Set `Filter` to `attributes.com.example.data_source : "training"`
5. Verify data
6. Set `Filter` to `attributes.com.example.data_source : "training" and attributes.com.example.classification : "fraud"`
7. Verify data
