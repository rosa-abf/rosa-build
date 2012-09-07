## 3. Platform

### 3.1. Platform data

This request will return you all needed data about platforms list into JSON format.

URL: /api/v1/platforms/:id.json

PARAMS:
* :id - identifier of current project

TYPE: GET

RESPONSE:

```json
{
  "id": <platform id>,
  "name": <platform name>,
  "description": <platform description>,
  "parent_platform_id": <parent platform id>,
  "created_at": <platform created at>,
  "updated_at": <platform updated_at>,
  "released": <platform released>,
  "visibility": <platform visibility>,
  "platform_type": <platform type>,
  "distrib_type": <platform distribution type>,
  "owner": {
    "id": <owner id>,
    "name": <owner name>,
    "type": <owner type>,
    "url": <owner data path>
  },
  "repositories": [
    {
      "id": <repository for package storage id>, 
      "name": <repository for package storage name>,
      "url":  <path to repository data page>
    }
    ...
  ],
  "url": <platform path>
}

```

EXAMPLE:

```json
{
  "id": 1,
  "name": "mdv_main",
  "description": "mdv_main",
  "parent_platform_id": null,
  "created_at": 2012-05-09 11:26:46 UTC ,
  "updated_at": "2012-06-09 11:26:46 UTC ",
  "released": <platform released>,
  "visibility": "open",
  "platform_type": "main",
  "distrib_type": "mdv",
  "owner": {
    "id":5,
    "name":"Timothy Bobrov",
    "type":"User",
    "url":"/users/5.json"
  },
  "repositories": [
    {
      "id": 1, 
      "name": "main",
      "url":  "/api/v1/repositories/1.json"
    },
    {
      "id": 2, 
      "name": "release",
      "url":  "/api/v1/repositories/2.json"
    }
  ],
  "url": "/api/v1/platforms/1.json"
}

```

### 3.2. Platform list

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

```json
{
  "platforms":[
    {
      "id": <platform id>,
      "name": <platform name>,
      "platform_type": <platform type>,
      "visibility": <platform visibility (hidden/open)>,
      "owner":{
        "id": <owner id>,
        "name": <owner name>,
        "type": <owner type>,
        "url": <path to owner data>
      },
      "url": <path to platform data>
    },
    ...
  ]
}

```

EXAMPLE:

```json
{
  "platforms":[
    {
      "id":26,
      "name":"fucktest",
      "platform_type":"mail",
      "visibility":"hidden",
      "owner":{
        "id":5,
        "name":"Timothy Bobrov1",
        "type":"User",
        "url":"/users/5.json"
      },
      "url":"/api/v1/platforms/26.json"
    },
    {
      "id":17,
      "name":"aaa",
      "platform_type":"main",
      "visibility":"hidden",
      "owner":{
        "id":5,
        "name":"Timothy Bobrov",
        "type":"User",
        "url":"/timothy_bobrov.json"
      },
      "url":"/api/v1/platforms/17.json"
    },
    {
      "id":18,
      "name":"timothy_tsvetkov",
      "platform_type":"main",
      "visibility":"hidden",
      "owner":{
        "id":4,
        "name":"Yaroslav Garkin",
        "type":"User",
        "url":"/users/4.json"
      },
    "url":"/api/v1/platforms/18.json"
    },
  ],"url":"/api/v1/platforms.json"
}

```
