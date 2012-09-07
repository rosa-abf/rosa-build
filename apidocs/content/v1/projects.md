## 1. Projects

### 1.1. Project data

This request will return you all needed data of requested project into JSON format.

URL: /api/v1/projects/:id.json

TYPE: GET

PARAMS:
* :id - identifier of current project

RESPONSE:

```json
{
  "project":
    {
      "id": <resource id>,
      "name": <name>,
      "created_at": <created at date and time>,
      "updated_at" <updated at date and time>,
      "visibility": <visibility (open/hidden)>,
      "description": <description>,
      "ancestry": <project ancestry>,
      "has_issues": <true if issues enabled>,
      "has_wiki": <true if wiki enabled>,
      "default_branch": <git branch used by default>,
      "is_package": <true if project is package>,
      "average_build_time": <average build time for this project>,
      "owner": {
        "id": <parent owner id>,
        "name": <parent owner name>,
        "url": <url to owner profile>
      },
      "repositories": [
        {
          "id": <repository for package storage id>, 
          "name": <repository for package storage name>,
          "url":  <path to repository data page>,
          "platform": {
            "id": <repository platform id>, 
            "name": <repository platform name>,
            "url": <path to repository platform data page>
          }
        },
        ....
      ],
      "url": <url to build list page>
    }
}

```

EXAMPLE:

```json
{
  "project":
  {
    "id":4661,
    "name":"hwinfo",
    "created_at":"2011-09-05T14:33:25Z",
    "updated_at":"2012-02-29T18:16:02Z",
    "visibility":"open",
    "description":"asfsafafsfasf fas fasfsa fas  fasfa s",
    "ancestry":null,
    "has_issues":true,
    "has_wiki":false,
    "default_branch":"master",
    "is_package":true,
    "average_build_time":0,
    "owner":{
      "id":4,
      "name":"Yaroslav Garkin",
      "type":"User",
      "url":"/users/4.json"
    },
    "repositories": [
      {
        "id": 1, 
        "name": "main",
        "url":  "/api/v1/repositories/1.json",
        "platform": {
          "id": 1, 
          "name": "mdv_main",
          "url": "/api/v1/platforms/1.json"
        }
      },
      {
        "id": 3, 
        "name": "main",
        "url":  "/api/v1/repositories/3.json",
        "platform": {
          "id": 3, 
          "name": "warpc_personal",
          "url": "/api/v1/platforms/3.json"
        }
      }
    ],
  },
  "url":"/api/v1/projects/4661.json"}
}

```

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

```json
{
  "project":
    {
      "id": <resource id>,
      "name": <name>,
      "visibility": <visibility (open/hidden)>,
      "owner": {
        "id": <owner id>,
        "name": <owner name>,
        "url": <url to owner profile>
      },
      "url": <url to project data page>
    }
}

```

EXAMPLE:

```json
{
  "project":
    {
      "id":4661,
      "name":"hwinfo",
      "visibility":"open",
      "owner":{
        "id":4,
        "name":"Yaroslav Garkin",
        "type":"User",
        "url":"/users/4.json"
      },
      "url":"/api/v1/projects/4661.json"
    }
}

```

