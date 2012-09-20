---
title: Projects | GitHub API
---

* <a href="#project-data">Project data</a>
* <a href="#project-id-get-by-name-and-owner">Project id get by name and owner</a>

## Project data

This request will return you all needed data of requested project into JSON format.

### Url:

    GET /api/v1/projects/:id.json

### Params:

* `id`: identifier of current project

### Response:

<%= json(:project_data_response) %>

### Example:

<%= json(:project_data_response_example) %>

## Project id get by name and owner

This request will return you all needed data about projects list into JSON format and also you can filter them by name.

### Url:

    GET /api/v1/projects/get_id.json?name=:project_name&owner=:owner_name

### Parameters:

* `project_name`: project name
* `owner_name`: project owner name

### Request examples:

    /api/v1/projects/get_id.json?name=rails&owner=warpc

### Response:

<%= json(:project_get_id_response) %>

### Example:

<%= json(:project_get_id_response_example) %>

