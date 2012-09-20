---
title: Project Build | GitHub API
---

* <a href="#show-build-data">Show build data</a>
* <a href="#create-build-task">Create build task</a>
* <a href="#cancel-build-task">Cancel build task</a>
* <a href="#publish-build-task">Publish build task</a>
* <a href="#reject-publish-build-task">Reject publish build task</a>
* <a href="#search">Search</a>
* <a href="#destroy-build-task">Destroy build task</a>

## Show build data

This request will return you all needed data of requested build task into JSON format.

### Url:

    GET /api/v1/buils_lists/:id.json

### Params:
* `id`: identifier of current build task

### Response:

<%= json(:build_list_show_parameters) %>

### Example:

<%= json(:build_list_show_example) %>

## Create build task

By this request you can create build task for project.

### Create parameters:

<%= json(:build_list_create_parameters) %>

**Note: Request creates build list for each architecture and base platform.**

### Posible update types:

    security
    bugfix
    enhancement
    recommended
    newpackage

### Url:

    POST /api/v1/api/v1/build_lists.json

### Request example:

<%= json(:build_list_create_example) %>

### Response:

<%= json(:build_list_create_response) %>

### Response example:

<%= json(:build_list_create_response_example) %>

## Cancel build task

By this request you can cancel build task.

### Url:

    PUT /api/v1/buils_lists/:id/cancel.json

### Response:

<%= json(:build_list_cancel_response) %>

### Example:

<%= json(:build_list_cancel_response_example) %>

&nbsp;

<%= json(:build_list_cancel_response_example2) %>

## Publish build task

By this request you can publish build task.

### Url:

    PUT /api/v1/buils_lists/:id/publish.json

### Response:

<%= json(:build_list_publish_response) %>

### Example:

<%= json(:build_list_publish_response_example) %>

&nbsp;

<%= json(:build_list_publish_response_example2) %>

## Reject publish build task

By this request you can reject publish build task.

### Url:

    PUT /api/v1/buils_lists/:id/reject_publish.json

### Response:

<%= json(:build_list_reject_response) %>

### Example:

<%= json(:build_list_reject_response_example) %>

&nbsp;

<%= json(:build_list_reject_response_example2) %>

## Search

By this way you can search build list you need.

### Search params:

* `page` - page number of build lists results list
* `per_page` - amount of build list per one page (default 30, maximum 100)
* `filter[status]` - integer code of the build status
* `filter[arch_id]` - identifier of the architecture
* `filter[is_circle]` - recurrent build (true or false)
* `filter[project_name]` - project name
* `filter[created_at_start / created_at_end]` - start and end of the build list creation date diapason(unixtime)
* `filter[updated_at_start / updated_at_end]` - start and end of the build list last change date diapason(unixtime)
* `filter[ownership]` - ownership type (owned/related/index)
* `filter[mass_build_id]` - mass build identifier
* `filter[save_to_platform_id]` - platform id for build save


### Build list posible statuses

        Build error: 666
        Build has been published: 6000
        Publishing rejected: 9000
        Build is being published: 7000
        Publishing error: 8000
        Dependences not found: ?
        Waiting for response: 4000
        Build pending: 2000
        Dependency test failed: ?
        Binary test failed: ?
        Build canceled: 5000
        Build complete: 0
        Build started: 3000
        Platform not found: 1
        Platform pending: 2
        Project not found: 3
        Project version not found: 4

### Url:

    GET /api/v1/build_lists.json?<search params>

### Response:

<%= json(:build_list_search_response) %>

### Example of request url:

> /api/v1/build_lists.json?filter[project_name]=rails

> /api/v1/build_lists.json?filter[ownership]=owned&filter[status]=6000&filter[arch_id]=2

### Examples of responses:

<%= json(:build_list_search_response_example) %>

## Destroy build task

You can't destroy build list. Only cancel it. :)

