---
title: Platforms | GitHub API
---
* <a href="#platform-data">Platform data</a>
* <a href="#platform-list">Platform list</a>

## Platform data

This request will return you all needed data about platforms list into JSON format.

URL:

    GET /api/v1/platforms/:id.json

### Params:

* `id`: identifier of current project

### Response:

<%= json(:platform_data_response) %>

### Example:

<%= json(:platform_data_response_example) %>

## Platform list

This request will return you all needed data about platform into JSON format.

### Url:

    GET /api/v1/platforms.json

### Parameters:

* `type`: filter platforms by type (main/personal). Also you can don't set the type to get all of the platforms

### Request examples:

    /api/v1/platforms.json?type=main
    /api/v1/platforms.json?type=personal
    /api/v1/platforms.json

### Response:

<%= json(:platform_list_response) %>

### Example:

<%= json(:platform_list_response_example) %>

