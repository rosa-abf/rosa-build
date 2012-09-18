## 1. Projects

### 1.1. Project data

This request will return you all needed data of requested project into JSON format.

URL: /api/v1/projects/:id.json

TYPE: GET

PARAMS:

* :id - identifier of current project

RESPONSE:

<%= json(:project_data_response) %>

EXAMPLE:

<%= json(:project_data_response_example) %>

### 1.2. Project id get by name and owner

This request will return you all needed data about projects list into JSON format and also you can filter them by name.

URL: /api/v1/projects/get_id.json?name=:project_name&owner=:owner_name

TYPE: GET

PARAMETERS:

* project_name - project name
* owner_name - project owner name

REQUEST EXAMPLES:

    /api/v1/projects/get_id.json?name=rails&owner=warpc

RESPONSE:

<%= json(:project_get_id_response) %>

EXAMPLE:

<%= json(:project_get_id_response_example) %>

