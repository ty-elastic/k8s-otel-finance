# A Modern Elasticsearch Logging Workflow

## Overview

Over the last few years, Elastic has rebuilt its logging toolset to match the scale of the very systems it is observing. Elastic's logging tools let SREs and Developers quickly and easily employ parsing, aggregations, and visualizations (ES|QL, Streams) as part of their daily-driver RCA workflows. Elastic has carefully woven ML (log rate analysis, log pattern analysis) and AI (generating GROK patterns and ES|QL queries) into those tools in ways which remove tedious and complex tasks, allowing the SRE and Developer to focus their attention on quickly and accurately determining a Root Cause. This in turn helps keeps MTTR constant, regardless of growth in the scale and complexity of the system you are observing.

This is a hands-on workshop showcasing the latest Elasticsearch log analytics employed in a practical workflow to debug a problem.

## Target Audience

* SREs
* Developers

## Applicability

* Existing Customers (introduce existing customers to ES|QL and Streams)
* New Customers (introduce new customer to the Elastic logging workflow)

## Learnings

Participants will walk away from the workshop with an introduction to:

* Using ES|QL to search logs
* Using ES|QL to parse logs at query-time
* Using ES|QL to do advanced aggregations, analytics, and visualizations
* Creating a useful dashboard
* Using ES|QL to create Alerts
* Using AI Assistant to help write ES|QL queries
* Using Streams to setup ingest-time log processing pipeline (GROK parsing, geo-location, User Agent parsing)
* Setting up SLOs
* Using Maps to visualize geographic information
* Scheduling dashboard reports
* Setting up a Pivot Transform
* Setting up RBAC
* Setting up data retention
