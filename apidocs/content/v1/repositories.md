---
title: Platforms | GitHub API
---

## 1. Repositories

### 1.1. Repository data

This request will return you all needed data about repositories list into JSON format.

URL: /api/v1/repositories/:id.json

PARAMS:

* :id - identifier of current project

TYPE: GET

RESPONSE:

<%= json(:repository_data_response) %>

EXAMPLE:

<%= json(:repository_data_response_example) %>

