---
title: Repositories | GitHub API
---

## Repository data

This request will return you all needed data about repositories list into JSON format.

### Url:

    GET /api/v1/repositories/:id.json

### Params:

* `id`: identifier of current project

### Response:

<%= json(:repository_data_response) %>

### Example:

<%= json(:repository_data_response_example) %>

