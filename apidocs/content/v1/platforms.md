---
title: Platforms | ABF API
---

# Platforms API

* <a href="#get-a-single-platform">Get a single platform</a>
* <a href="#list-platforms">List platforms</a>

## Get a single platform

    GET /api/v1/platforms/:id.json

### Parameters:

id
: _Integer_ identifier of current platform

### Response:

<%= json(:platform_data_response) %>

### Example:

<%= json(:platform_data_response_example) %>

## List platforms

    GET /api/v1/platforms.json

### Parameters:

type
: _Optional_ filter platforms by type: `main` or `personal`. Also you can don't set the type to get all of the platforms

### Request examples:

    /api/v1/platforms.json?type=main
    /api/v1/platforms.json?type=personal
    /api/v1/platforms.json

### Response:

<%= json(:platform_list_response) %>

### Example:

<%= json(:platform_list_response_example) %>

