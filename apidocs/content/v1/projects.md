---
title: Projects | ABF API
---

# Projects API

* <a href="#get-a-single-project">Get a single project</a>
* <a href="#get-project-id">Get project id</a>

## Get a single project

    GET /api/v1/projects/:id.json

### Parameters:

id
: _Integer_ identifier of current project

### Response:

<%= json(:project_data_response) %>

### Example:

<%= json(:project_data_response_example) %>

## Get project id

    GET /api/v1/projects/get_id.json?name=:project_name&owner=:owner_name

### Parameters:

project_name
: _String_ project name

owner_name: 
: _String_ project owner name

### Request examples:

    /api/v1/projects/get_id.json?name=rails&owner=warpc

### Response:

<%= json(:project_get_id_response) %>

### Example:

<%= json(:project_get_id_response_example) %>

