### 4. Architectures list

This request will return you all needed data about posible architectures into JSON format.

URL: /api/v1/arches.json

TYPE: GET

RESPONSE:

```json
{
  "architectures": [
    {
      "id": <architecture identifier>,
      "name": <architecture name>
    },
    ...
  ]
```

RESPONSE EXAMPLE:

```json
{
  "architectures": [
    {
      "id": 1,
      "name": "x86_64"
    },
    {
      "id": 2,
      "name": "i586"
    },
    ...
  ]
```
