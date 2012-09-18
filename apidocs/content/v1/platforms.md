---
title: Platforms | GitHub API
---

* <a href="#platform-data">Platform data</a>
* <a href="#platform-list">Platform list</a>

## 1. Platforms

### 1.1. Platform data

This request will return you all needed data about platforms list into JSON format.

URL: /api/v1/platforms/:id.json

PARAMS:

* :id - identifier of current project

TYPE: GET

RESPONSE:

<%= json(:platform_data_response) %>

EXAMPLE:

<%= json(:platform_data_response_example) %>

### 1.2. Platform list

This request will return you all needed data about platform into JSON format.

URL: /api/v1/platforms.json

TYPE: GET

PARAMETERS:

* type - filter platforms by type (main/personal). Also you can don't set the type to get all of the platforms

REQUEST EXAMPLES:

    /api/v1/platforms.json?type=main
    /api/v1/platforms.json?type=personal
    /api/v1/platforms.json

RESPONSE:

<%= json(:platform_list_response) %>


EXAMPLE:

<%= json(:platform_list_response_example) %>

