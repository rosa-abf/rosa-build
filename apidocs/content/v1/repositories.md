## 2. Repository

### 2.1. Repository data

This request will return you all needed data about repositories list into JSON format.

URL: /api/v1/repositories/:id.json

PARAMS:
* :id - identifier of current project

TYPE: GET

RESPONSE:

```json
{
  "repository":
    {
      "id": <resource id>,
      "name": <name>,
      "created_at": <created at date and time>,
      "updated_at": <updated at date and time>,
      "description": <description>,
      "platform": {
        "id": <platform id>,
        "name": <platform name>,
        "url": <url to platform>
      },
      "url": <url to platform page>
    },
  "url": <url to platforms list page>
}

```

EXAMPLE:

```json
{
  "repository":
    {
      "id":30,
      "name":"main",
      "platform":{
        "id":41,
        "name":"my_personal",
        "url":"/api/v1/platforms/41.json"
      },
    },
  "url":"/api/v1/repositories/30.json"
}

```

