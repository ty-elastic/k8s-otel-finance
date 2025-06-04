---
slug: application
id: ylynqfneshqn
type: challenge
title: Apply Model
tabs:
- id: xs7t9jhyoxnu
  title: Elastic
  type: service
  hostname: kubernetes-vm
  path: /app/ml/trained_models
  port: 30001
- id: 9x4dqx4eqm9c
  title: Trader
  type: service
  hostname: host-1
  path: /#/train
  port: 9090
difficulty: ""
timelimit: 0
enhanced_loading: null
---

# Apply Model

1. [button label="Elastic"](tab-0)
2. Find model `classifcation-*`
3. `...` select `Deploy model`
4. Under `1. Details` select `Continue`
5. Under `2. Configure processor` select `Continue`
6. Under `3. Handle failures` select `Continue`
7. Under `4. Test (Optional)` select `Continue`
8. Under `5. Create` select `Create pipeline`
9. Under `Next steps` open `Reindex with pipeline` and set `Destination index name` to `classified_trades` and enable `Create data view`
10. Under `Next steps` open `Reindex with pipeline` and click `Reindex`
11. Select `View classified_trades(external, opens in a new tab or window) in Discover.`

# Check Results
1. In `Discover`
2. Set `Filter` to `attributes.com.example.data_source : "monkey" and ml.inference.classification.classification :"fraud"`

# Validate with Dashboard

1. [button label="Elastic"](tab-0)
2. Navigate to Dashboards > Fraudulent Transactions
3. Validate that graphs match your fruadulent transactions