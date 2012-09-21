require 'pp'
require 'yajl/json_gem'
require 'stringio'
require 'cgi'

module GitHub
  module Resources
    module Helpers
      STATUSES = {
        200 => '200 OK',
        201 => '201 Created',
        202 => '202 Accepted',
        204 => '204 No Content',
        301 => '301 Moved Permanently',
        304 => '304 Not Modified',
        401 => '401 Unauthorized',
        403 => '403 Forbidden',
        404 => '404 Not Found',
        409 => '409 Conflict',
        422 => '422 Unprocessable Entity',
        500 => '500 Server Error'
      }

      DefaultTimeFormat = "%B %-d, %Y".freeze

      def post_date(item)
        strftime item[:created_at]
      end

      def strftime(time, format = DefaultTimeFormat)
        attribute_to_time(time).strftime(format)
      end

      def gravatar_for(login)
        %(<img height="16" width="16" src="%s" />) % gravatar_url_for(login)
      end

      def gravatar_url_for(login)
        md5 = AUTHORS[login.to_sym]
        default = "https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-user-420.png"
        "https://secure.gravatar.com/avatar/%s?s=20&d=%s" %
          [md5, default]
      end

      def headers(status, head = {})
        css_class = (status == 204 || status == 404) ? 'headers no-response' : 'headers'
        lines = ["Status: #{STATUSES[status]}"]
        head.each do |key, value|
          case key
            when :pagination
              lines << 'Link: <https://api.github.com/resource?page=2>; rel="next",'
              lines << '      <https://api.github.com/resource?page=5>; rel="last"'
            else lines << "#{key}: #{value}"
          end
        end

        lines << "X-RateLimit-Limit: 500"
        lines << "X-RateLimit-Remaining: 499"

        %(<pre class="#{css_class}"><code>#{lines * "\n"}</code></pre>\n)
      end

      def json(key)
        hash = case key
          when Hash
            h = {}
            key.each { |k, v| h[k.to_s] = v }
            h
          when Array
            key
          else Resources.const_get(key.to_s.upcase)
        end

        hash = yield hash if block_given?

        %(<pre class="highlight"><code class="language-javascript">) +
          JSON.pretty_generate(hash) + "</code></pre>"
      end

      def text_html(response, status, head = {})
        hs = headers(status, head.merge('Content-Type' => 'text/html'))
        res = CGI.escapeHTML(response)
        hs + %(<pre class="highlight"><code>) + res + "</code></pre>"
      end
    end

    #==============================================================================
    # ABF constants
    #==============================================================================

    BUILD_LIST_SHOW_EXAMPLE = {
      "build_list" =>
        {
          "id" => 10,
          "name" => "evil_tools",
          "container_path" => "/rosa2012/container/evil_tools",
          "status" => 6000,
          "project_version" => "latest_rosa2012",
          "package_version" => "latest_rosa2012",
          "project" => {
            "id" => 666,
            "name" => "evil_tools",
            "fullname" => "",
            "url" => "/api/v1/projects/1"
          },
          "build_for_platform" => {
            "id" => 1,
            "name" => "rosa2012",
            "url" => "/api/v1/platforms/1"
          },
          "save_to_repository" => {
            "id" => 12, 
            "name" => "mr_evil/personal",
            "url" =>  "/api/v1/repositories/12",
            "platform" => {
              "id" => 2, 
              "name" => "cocos_lts",
              "url" => "/api/v1/platforms/2"
            }
          },
          "arch" => {
            "id" => 1,
            "name" => "x84_64" 
          },
          "notifed_at" => 1348168905,
          "is_circle" => false,
          "update_type" => "bugfix",
          "build_requires" => false,
          "auto_publish" => true,
          "commit_hash" => "4edafbe69632173a1800c4d7582b60b46bc1fb55",
          "priority" => 0,
          "duration" => nil,
          "build_log_url" => "/downloads/warpc_personal/container/evil_tools-680163/log/evil_tools/build.log",
          "advisory" => {
            "id" => 666,
            "name" => "at",
            "description" => "warpc/at",
            "url" => "/api/v1/advisories/666"
          },
          "mass_build" => {
            "id" => 666,
            "name" => "rosa2012lts (main)",
            "url" => "/api/v1/mass_builds/666"
          },
          "owner" => {
            "id" => 49,
            "name" => "Mr. Evil",
            "url" => "/users/49.json"
          },
          "include_repos" => [
            {
              "id" => 16, 
              "name" => "main",
              "url" => "/api/v1/repositories/16.json",
              "platform" => {
                "id" => 16, 
                "name" => "warpc_personal",
                "url" => "/api/v1/platforms/16.json"
              }
            }
          ],
          "url" => "/api/v1/build_lists/10.json"
        }
    }

    BUILD_LIST_SHOW_PARAMETERS = {
      "build_list" =>
        {
          "id" => "resource id",
          "name" => "name",
          "container_path" => "Container path",
          "status" => "status code",
          "project_version" => "parent project version",
          "package_version" => "package version",
          "project" => {
            "id" => "project id",
            "name" => "project name",
            "fullname" => "project fullname",
            "url" => "url to project data page" 
          },
          "build_for_platform" => {
            "id" => "platform id",
            "name" => "platform name",
            "url" => "platform data page path"
          },
          "save_to_repository" => {
            "id" => "repository for package storage id", 
            "name" => "repository for package storage name",
            "url" =>  "path to repository data page",
            "platform" => {
              "id" => "repository platform id", 
              "name" => "repository platform name",
              "url" => "path to repository platform data page"
            }
          },
          "arch" => {
            "id" => "build architecture id",
            "name" => "build architecture name" 
          },
          "is_circle" => "recurrent build",
          "update_type" => "update type",
          "build_requires" => "build with all the required packages",
          "auto_publish" => "automated publising",
          "commit_hash" => "last commit hash of project source",
          "priority" => "build priority",
          "duration" => "build duration in seconds",
          "build_log_url" => "build list log url",
          "advisory" => {
            "id" => "advisory id",
            "name" => "advisory name",
            "description" => "advisory description",
            "url" => "path to advisory data page" 
          },
          "mass_build" => {
            "id" => "mass_build id",
            "name" => "mass_build name",
            "url" => "path to mass_build data page" 
          },
          "owner" => {
            "id" => "project owner id",
            "name" => "project owner name",
            "url" => "url to owner profile"
          },
          "include_repos" => [
            {
              "id" => "included repository id", 
              "name" => "included repository name",
              "url" => "path to included repository data page",
              "platform" => {
                "id" => "repository platform id", 
                "name" => "repository platform name",
                "url" => "path to repository platform data page"
              }
            }
          ],
          "url" => "url to build list page"
        }
    }


    BUILD_LIST_CREATE_PARAMETERS = {
      "build_list"=> {
        "project_id"=> "project id",
        "commit_hash"=> "commit hash to build",
        "update_type"=> "one of the update types",
        "save_to_repository_id"=> "repository identifier for package storage",
        "build_for_platform_id"=> "platform identifier of platform for build",
        "auto_publish"=> "automated publising",
        "build_requires"=> "true if build with all the required packages",
        "include_repos[]"=> [
          "included repository id for each selected platform"
        ],
        "arch_id"=> "architecture identifier"
      }
    }

    BUILD_LIST_CREATE_EXAMPLE = {
      "build_list"=> {
        "project_id"=> "10",
        "commit_hash"=> "751b0cad9cd1467e735d8c3334ea3cf988995fab",
        "update_type"=> "bugfix",
        "save_to_repository_id"=> 12,
        "build_for_platform_id"=> 2,
        "auto_publish"=> true,
        "build_requires"=> true,
        "include_repos[]"=> [
          54,
          53
        ],
        "arch_id"=> 1
      }
    }

    BUILD_LIST_CREATE_RESPONSE = {
      "build_list" =>
        {
          "id" => "build list id (null if failed)",
          "message" => "success of fail message"
        }
    }

    BUILD_LIST_CREATE_RESPONSE_EXAMPLE = {
      "build_list"=>
        {
          "id"=> 56,
          "message"=> "Build list for project version 'beta_2012', platform 'rosa2012' and architecture 'i586' has been created successfully"
        }
    }

    BUILD_LIST_CANCEL_RESPONSE = {
      "is_canceled"=> "true or false",
      "url"=> "url to build list page",
      "message"=> "success of fail message"
    }

    BUILD_LIST_CANCEL_RESPONSE_EXAMPLE = {
      "is_canceled"=> true,
      "url"=> "/api/v1/build_lists/10.json",
      "message"=> "Build canceled"
    }

    BUILD_LIST_CANCEL_RESPONSE_EXAMPLE2 = {
      "is_canceled"=> false,
      "url"=> "/api/v1/build_lists/10.json",
      "message"=> "Errors during build cancelation!"
    }

    BUILD_LIST_PUBLISH_RESPONSE = {
      "is_published"=> "true or false", # May be just result name will be better
      "url"=> "url to build list page",
      "message"=> "success of fail message"
    }

    BUILD_LIST_PUBLISH_RESPONSE_EXAMPLE = {
      "is_published"=> true,
      "url"=> "/api/v1/build_lists/10.json",
      "message"=> "Build is queued for publishing"
    }

    BUILD_LIST_PUBLISH_RESPONSE_EXAMPLE2 = {
      "is_published"=> false,
      "url"=> "/api/v1/build_lists/10.json",
      "message"=> "Errors during build publishing!"
    }

    BUILD_LIST_REJECT_RESPONSE = {
      "is_rejected"=> "true or false", # May be just result name will be better
      "url"=> "url to build list page",
      "message"=> "success or fail message"
    }

    BUILD_LIST_REJECT_RESPONSE_EXAMPLE = {
      "is_rejected"=> true,
      "url"=> "/api/v1/build_lists/10.json",
      "message"=> "Build is rejected"
    }

    BUILD_LIST_REJECT_RESPONSE_EXAMPLE2 = {
      "is_rejected"=> false,
      "url"=> "/api/v1/build_lists/10.json",
      "message"=> "Errors during build rejecting!"
    }

    BUILD_LIST_SEARCH_RESPONSE = {
      "build_lists"=> [
        {
          "id"=> "build list id",
          "name"=> "build list name",
          "status"=> "build list status",
          "url"=> "build list page"
        }
      ],
      "url"=> "current url for build lists page"
    }

    BUILD_LIST_SEARCH_RESPONSE_EXAMPLE = {
      "build_lists"=> [
        {
          "id"=> 25,
          "name"=> "evil_tools",
          "status"=> 6000,
          "url"=> "/api/v1/build_lists/25.json"
        },
        {
          "id"=> 26,
          "name"=> "evil_tools",
          "status"=> 6000,
          "url"=> "/api/v1/build_lists/26.json"
        }
      ],
      "url"=> "/api/v1/build_lists.json"
    }

    ERROR_404 = {
      "status"=> 404,
      "message"=> "Page not found"
    }

    ERROR_500 = {
      "status"=> 500,
      "message"=> "Something went wrong. We've been notified about this issue and we'll take a look at it shortly."
    }

    ERROR_503 = {
      "status"=> 503,
      "message"=> "We update the site, it will take some time. We are really trying to do it fast. We apologize for any inconvenience.."
    }

    ERROR_401 = {
      "status"=> 401,
      "message"=> "Requires authentication"
    }

    ERROR_403 = {
      "message"=> "Forbidden. Sorry, you don't have enough rights for this action!"
    }

    ERROR_AUTH = {
      "message" => "You need to sign in or sign up before continuing."
    }

    ERROR_WRONG_PASS = {
      "message" => "Invalid email or password."
    }

    ERROR_RATE_LIMIT = {
      "message" => "403 Forbidden | Rate Limit Exceeded"
    }

    PROJECT_DATA_RESPONSE = {
      "project"=>
        {
          "id" => "resource id",
          "name" => "name",
          "created_at" => "created at date and time",
          "updated_at" => "updated at date and time",
          "visibility" => "visibility (open/hidden)",
          "description" => "description",
          "ancestry" => "project ancestry",
          "has_issues" => "true if issues enabled",
          "has_wiki" => "true if wiki enabled",
          "default_branch" => "git branch used by default",
          "is_package" => "true if project is package",
          "average_build_time" => "average build time for this project",
          "owner" => {
            "id" => "parent owner id",
            "name" => "parent owner name",
            "url" => "url to owner profile"
          },
          "repositories" => [
            {
              "id" => "repository for package storage id",
              "name" => "repository for package storage name",
              "url" => "path to repository data page",
              "platform" => {
                "id" => "repository platform id",
                "name" => "repository platform name",
                "url" => "path to repository platform data page"
              }
            }
          ],
          "url" => "url to build list page"
        }
    }

    PROJECT_DATA_RESPONSE_EXAMPLE = {
      "project" =>
      {
        "id" => 4661,
        "name" => "hwinfo",
        "created_at" => 1348168705,
        "updated_at" => 1348168905,
        "visibility" => "open",
        "description" => "asfsafafsfasf fas fasfsa fas  fasfa s",
        "ancestry" => nil,
        "has_issues" => true,
        "has_wiki" => false,
        "default_branch" => "master",
        "is_package" => true,
        "average_build_time" => 0,
        "owner" => {
          "id" => 4,
          "name" => "Yaroslav Garkin",
          "type" => "User",
          "url" => "/users/4.json"
        },
        "repositories" => [
          {
            "id" => 1,
            "name" => "main",
            "url" => "/api/v1/repositories/1.json",
            "platform" => {
              "id" => 1, 
              "name" => "mdv_main",
              "url" => "/api/v1/platforms/1.json"
            }
          },
          {
            "id" => 3, 
            "name" => "main",
            "url" => "/api/v1/repositories/3.json",
            "platform" => {
              "id" => 3, 
              "name" => "warpc_personal",
              "url" => "/api/v1/platforms/3.json"
            }
          }
        ],
      },
      "url" => "/api/v1/projects/4661.json"
    }

    PROJECT_GET_ID_RESPONSE = {
      "project" =>
        {
          "id" => "resource id",
          "name" => "name",
          "visibility" => "visibility (open/hidden)",
          "owner" => {
            "id" => "owner id",
            "name" => "owner name",
            "url" => "url to owner profile"
          },
          "url" => "url to project data page"
        }
    }

    PROJECT_GET_ID_RESPONSE_EXAMPLE = {
      "project" =>
        {
          "id" => 4661,
          "name" => "hwinfo",
          "visibility" => "open",
          "owner" => {
            "id" => 4,
            "name" => "Yaroslav Garkin",
            "type" => "User",
            "url" => "/users/4.json"
          },
          "url" => "/api/v1/projects/4661.json"
        }
    }

    REPOSITORY_DATA_RESPONSE = {
      "repository" =>
        {
          "id" => "resource id",
          "name" => "name",
          "created_at" => "created at date and time",
          "updated_at" => "updated at date and time",
          "description" => "description",
          "publish_without_qa" => "publication without QA",
          "platform" => {
            "id" => "platform id",
            "name" => "platform name",
            "url" => "url to platform"
          },
          "url" => "url to platform page"
        },
      "url" => "url to platforms list page"
    }

    REPOSITORY_DATA_RESPONSE_EXAMPLE = {
      "repository" =>
        {
          "id" => 30,
          "name" => "main",
          "publish_without_qa" => true,
          "platform" => {
            "id" => 41,
            "name" => "my_personal",
            "url" => "/api/v1/platforms/41.json"
          },
        },
      "url" => "/api/v1/repositories/30.json"
    }

    PLATFORM_DATA_RESPONSE = {
      "id" => "platform id",
      "name" => "platform name",
      "description" => "platform description",
      "parent_platform_id" => "parent platform id",
      "created_at" => "platform created at",
      "updated_at" => "platform updated_at",
      "released" => "platform released",
      "visibility" => "platform visibility",
      "platform_type" => "platform type",
      "distrib_type" => "platform distribution type",
      "owner" => {
        "id" => "owner id",
        "name" => "owner name",
        "type" => "owner type",
        "url" => "owner data path"
      },
      "repositories" => [
        {
          "id" => "repository for package storage id",
          "name" => "repository for package storage name",
          "url" => "path to repository data page"
        }
      ],
      "url" => "platform path"
    }

    PLATFORM_DATA_RESPONSE_EXAMPLE = {
      "id" => 1,
      "name" => "mdv_main",
      "description" => "mdv_main",
      "parent_platform_id" => nil,
      "created_at" => "1326990586" ,
      "updated_at" => "1337171843",
      "released" => "platform released",
      "visibility" => "open",
      "platform_type" => "main",
      "distrib_type" => "mdv",
      "owner" => {
        "id" => 5,
        "name" => "Timothy Bobrov",
        "type" => "User",
        "url" => "/users/5.json"
      },
      "repositories" => [
        {
          "id" => 1,
          "name" => "main",
          "url" => "/api/v1/repositories/1.json"
        },
        {
          "id" => 2, 
          "name" => "release",
          "url" => "/api/v1/repositories/2.json"
        }
      ],
      "url" => "/api/v1/platforms/1.json"
    }

    PLATFORM_LIST_RESPONSE = {
      "platforms" => [
        {
          "id" => "platform id",
          "name" => "platform name",
          "platform_type" => "platform type",
          "visibility" => "platform visibility (hidden/open)",
          "owner" =>{
            "id" => "owner id",
            "name" => "owner name",
            "type" => "owner type",
            "url" => "path to owner data"
          },
          "repositories" => [
            {
              "id" => "repository for package storage id",
              "name" => "repository for package storage name",
              "url" => "path to repository data page"
            }
          ],
          "url" => "path to platform data"
        }
      ]
    }

    PLATFORM_LIST_RESPONSE_EXAMPLE = {
      "platforms" => [
        {
          "id" => 26,
          "name" => "fucktest",
          "platform_type" => "mail",
          "visibility" => "hidden",
          "owner" => {
            "id" => 5,
            "name" => "Timothy Bobrov1",
            "type" => "User",
            "url" => "/users/5.json"
          },
          "repositories" => [
            {
              "id" => 26,
              "name" => "main",
              "url" => "/api/v1/repositories/26.json"
            },
            {
              "id" => 27, 
              "name" => "release",
              "url" => "/api/v1/repositories/27.json"
            }
          ],
          "url" => "/api/v1/platforms/26.json"
        },
        {
          "id" => 17,
          "name" => "aaa",
          "platform_type" => "main",
          "visibility" => "hidden",
          "owner" => {
            "id" => 5,
            "name" => "Timothy Bobrov",
            "type" => "User",
            "url" => "/timothy_bobrov.json"
          },
          "repositories" => [
            {
              "id" => 28,
              "name" => "main",
              "url" => "/api/v1/repositories/28.json"
            },
            {
              "id" => 29, 
              "name" => "release",
              "url" => "/api/v1/repositories/29.json"
            }
          ],
          "url" => "/api/v1/platforms/17.json"
        },
        {
          "id" => 18,
          "name" => "timothy_tsvetkov",
          "platform_type" => "main",
          "visibility" => "hidden",
          "owner" => {
            "id" => 4,
            "name" => "Yaroslav Garkin",
            "type" => "User",
            "url" => "/users/4.json"
          },
          "repositories" => [
            {
              "id" => 30,
              "name" => "main",
              "url" => "/api/v1/repositories/30.json"
            },
            {
              "id" => 31, 
              "name" => "release",
              "url" => "/api/v1/repositories/31.json"
            }
          ],
        "url" => "/api/v1/platforms/18.json"
        },
      ],"url" => "/api/v1/platforms.json"
    }

    ARCHITECTURE_LIST_RESPONSE = {
      "architectures" => [
        {
          "id" => "architecture identifier",
          "name" => "architecture name"
        }
      ]
    }

    ARCHITECTURE_LIST_RESPONSE_EXAMPLE = {
      "architectures" => [
        {
          "id" => 1,
          "name" => "x86_64"
        },
        {
          "id" => 2,
          "name" => "i586"
        }
      ]
    }

  end
end

include GitHub::Resources::Helpers
