---
title: RosaLab ABF API
---

# RosaLab ABF API

This describes the resources that make up the official Rosa ABF API. If you have any problems or requests please contact support.

**Note: This API is in a beta state. Breaking changes may occur.**

All of the urls in this manual have the same tail: .json. Because the default

* <a href="#schema">Schema</a>
* <a href="#client-errors">Client Errors</a>
* <a href="#http-verbs">HTTP Verbs</a>
* <a href="#authentication">Authentication</a>
* <a href="#pagination">Pagination</a>
* <a href="#rate-limiting">Rate Limiting</a>

## Schema

All API access is over HTTPS and all data is
sent and received as JSON.

<pre class="terminal">
$ curl -i https://abf.rosalinux.ru/api/v1

HTTP/1.1 302 Found
Server: nginx/1.0.12
Date: Mon, 20 Feb 2012 11:15:49 GMT
Content-Type: text/html;charset=utf-8
Connection: keep-alive
Status: 302 Found
X-RateLimit-Limit: 500
Location: http://abf.rosalinux.ru
X-RateLimit-Remaining: 499
Content-Length: 0

</pre>

Blank fields are included as `null` instead of being omitted.

All timestamps are returned in unixtime format:

    1346762587

## Client Errors

There are three possible types of client errors on API calls that
receive request bodies.

Request without authorization will return error message:

<%= json(:error_auth) %>
<br/>

But if you set wrong pass or email you will receive this:

<%= json(:error_wrong_pass) %>
<br/>

Rate limit exceed will return this:

<%= json(:error_rate_limit) %>
<br/>

Some requests can cause cancer of 404, 500 and 503 errors. In these situatins you will receive such data:

<%= json(:error_404) %>

&nbsp;

<%= json(:error_500) %>

&nbsp;

<%= json(:error_503) %>

&nbsp;

<%= json(:error_401) %>

If you don't have enough rights for requested action, you will receive
error response such this:

<%= json(:error_403) %>

and http status code will be 403.

## HTTP Verbs

Where possible, API v1 strives to use appropriate HTTP verbs for each
action.

GET
: Used for retrieving resources.

POST
: Used for creating resources, or performing custom actions (such as
merging a pull request).

PUT
: Used for replacing resources or collections. For PUT requests
with no `body` attribute, be sure to set the `Content-Length` header to zero.

DELETE
: Used for deleting resources.

## Authentication

We use *http auth basic* for authentification:

<pre class="terminal">
$ curl --user myuser@gmail.com:mypass -i https://abf.rosalinux.ru/api/v1
</pre>

## Pagination

Requests that return multiple items will be paginated to 30 items by
default.  You can specify further pages with the `?page` parameter.  For some
resources, you can also set a custom page size up to 100 with the `?per_page` parameter.

<pre class="terminal">
$ curl https://abf.rosalinux.ru/api/v1/build_lists.json?page=2&per_page=100
</pre>

The pagination info is included in [the Link
header](http://www.w3.org/Protocols/9707-link-header.html). It is important to
follow these Link header values instead of constructing your own URLs.

    Link: <https://abf.rosalinux.ru/api/v1/build_lists.json?page=3&per_page=100>; rel="next",
      <https://abf.rosalinux.ru/build_lists.json?page=50&per_page=100>; rel="last"

_Linebreak is included for readability._

The possible `rel` values are:

`next`
: Shows the URL of the immediate next page of results.

`last`
: Shows the URL of the last page of results.

`first`
: Shows the URL of the first page of results.

`prev`
: Shows the URL of the immediate previous page of results.

## Rate Limiting

We limit requests to API v3 to 5000 per hour.  This is keyed off either your
login, your OAuth token, or request IP.  You can check the returned HTTP
headers of any API request to see your current status:

<pre class="terminal">
$ curl -i https://abf.rosalinux.ru/whatever

HTTP/1.1 200 OK
Status: 200 OK
X-RateLimit-Limit: 500
X-RateLimit-Remaining: 496
</pre>

<br>

