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

      AUTHORS = {
        :technoweenie => '821395fe70906c8290df7f18ac4ac6cf'
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

        lines << "X-RateLimit-Limit: 5000"
        lines << "X-RateLimit-Remaining: 4999"

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
      "notifed_at" => "Tue, 03 Apr 2012 14 =>06 =>10 UTC +00 =>00",
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

#==============================================================================
# Github constants
#==============================================================================

    USER = {
      "login"        => "octocat",
      "id"           => 1,
      "avatar_url"   => "https://github.com/images/error/octocat_happy.gif",
      "gravatar_id"  => "somehexcode",
      "url"          => "https://api.github.com/users/octocat"
    }

    CONTRIBUTOR = USER.merge({
      "contributions" => 32
    })

    FULL_USER = USER.merge({
      "name"         => "monalisa octocat",
      "company"      => "GitHub",
      "blog"         => "https://github.com/blog",
      "location"     => "San Francisco",
      "email"        => "octocat@github.com",
      "hireable"     => false,
      "bio"          => "There once was...",
      "public_repos" => 2,
      "public_gists" => 1,
      "followers"    => 20,
      "following"    => 0,
      "html_url"     => "https://github.com/octocat",
      "created_at"   => "2008-01-14T04:33:35Z",
      "type"         => "User"
    })

    PRIVATE_USER = FULL_USER.merge({
      "total_private_repos" => 100,
      "owned_private_repos" => 100,
      "private_gists"       => 81,
      "disk_usage"          => 10000,
      "collaborators"       => 8,
      "plan"                => {
        "name"          => "Medium",
        "space"         => 400,
        "collaborators" => 10,
        "private_repos" => 20
      }
    })

    PUBLIC_KEY = {
      "url"   => "https://api.github.com/user/keys/1",
      "id"    => 1,
      "title" => "octocat@octomac",
      "key"   => "ssh-rsa AAA...",
    }

    REPO = {
      "url"              => "https://api.github.com/repos/octocat/Hello-World",
      "html_url"         => "https://github.com/octocat/Hello-World",
      "clone_url"        => "https://github.com/octocat/Hello-World.git",
      "git_url"          => "git://github.com/octocat/Hello-World.git",
      "ssh_url"          => "git@github.com:octocat/Hello-World.git",
      "svn_url"          => "https://svn.github.com/octocat/Hello-World",
      "mirror_url"       => "git://git.example.com/octocat/Hello-World",
      "id"               => 1296269,
      "owner"            => USER,
      "name"             => "Hello-World",
      "full_name"        => "octocat/Hello-World",
      "description"      => "This your first repo!",
      "homepage"         => "https://github.com",
      "language"         => nil,
      "private"          => false,
      "fork"             => false,
      "forks"            => 9,
      "watchers"         => 80,
      "size"             => 108,
      "master_branch"    => 'master',
      "open_issues"      => 0,
      "pushed_at"        => "2011-01-26T19:06:43Z",
      "created_at"       => "2011-01-26T19:01:12Z",
      "updated_at"       => "2011-01-26T19:14:43Z"
    }

    FULL_REPO = REPO.merge({
      "organization"     => USER.merge('type' => 'Organization'),
      "parent"           => REPO,
      "source"           => REPO,
      "has_issues"       => true,
      "has_wiki"         => true,
      "has_downloads"    => true
    })

    TAG = {
      "name"        => "v0.1",
      "commit"      => {
          "sha"     => "c5b97d5ae6c19d5c5df71a34c7fbeeda2479ccbc",
          "url"  => "https://api.github.com/octocat/Hello-World/commits/c5b97d5ae6c19d5c5df71a34c7fbeeda2479ccbc"
      },
      "zipball_url" => "https://github.com/octocat/Hello-World/zipball/v0.1",
      "tarball_url" => "https://github.com/octocat/Hello-World/tarball/v0.1",
    }

    BRANCHES = [
      {
        "name"   => "master",
        "commit" => {
          "sha" => "6dcb09b5b57875f334f61aebed695e2e4193db5e",
          "url" => "https://api.github.com/repos/octocat/Hello-World/commits/c5b97d5ae6c19d5c5df71a34c7fbeeda2479ccbc"
        }
      }
    ]

    BRANCH = {"name"=>"master",
 "commit"=>
  {"sha"=>"7fd1a60b01f91b314f59955a4e4d4e80d8edf11d",
   "commit"=>
    {"author"=>
      {"name"=>"The Octocat",
       "date"=>"2012-03-06T15:06:50-08:00",
       "email"=>"octocat@nowhere.com"},
     "url"=>
      "https://api.github.com/repos/octocat/Hello-World/git/commits/7fd1a60b01f91b314f59955a4e4d4e80d8edf11d",
     "message"=>
      "Merge pull request #6 from Spaceghost/patch-1\n\nNew line at end of file.",
     "tree"=>
      {"sha"=>"b4eecafa9be2f2006ce1b709d6857b07069b4608",
       "url"=>
        "https://api.github.com/repos/octocat/Hello-World/git/trees/b4eecafa9be2f2006ce1b709d6857b07069b4608"},
     "committer"=>
      {"name"=>"The Octocat",
       "date"=>"2012-03-06T15:06:50-08:00",
       "email"=>"octocat@nowhere.com"}},
   "author"=>
    {"gravatar_id"=>"7ad39074b0584bc555d0417ae3e7d974",
     "avatar_url"=>
      "https://secure.gravatar.com/avatar/7ad39074b0584bc555d0417ae3e7d974?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png",
     "url"=>"https://api.github.com/users/octocat",
     "id"=>583231,
     "login"=>"octocat"},
   "parents"=>
    [{"sha"=>"553c2077f0edc3d5dc5d17262f6aa498e69d6f8e",
      "url"=>
       "https://api.github.com/repos/octocat/Hello-World/commits/553c2077f0edc3d5dc5d17262f6aa498e69d6f8e"},
     {"sha"=>"762941318ee16e59dabbacb1b4049eec22f0d303",
      "url"=>
       "https://api.github.com/repos/octocat/Hello-World/commits/762941318ee16e59dabbacb1b4049eec22f0d303"}],
   "url"=>
    "https://api.github.com/repos/octocat/Hello-World/commits/7fd1a60b01f91b314f59955a4e4d4e80d8edf11d",
   "committer"=>
    {"gravatar_id"=>"7ad39074b0584bc555d0417ae3e7d974",
     "avatar_url"=>
      "https://secure.gravatar.com/avatar/7ad39074b0584bc555d0417ae3e7d974?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png",
     "url"=>"https://api.github.com/users/octocat",
     "id"=>583231,
     "login"=>"octocat"}},
 "_links"=>
  {"html"=>"https://github.com/octocat/Hello-World/tree/master",
   "self"=>"https://api.github.com/repos/octocat/Hello-World/branches/master"}}

 MERGE_COMMIT = {"commit"=>
  {"sha"=>"7fd1a60b01f91b314f59955a4e4d4e80d8edf11d",
   "commit"=>
    {"author"=>
      {"name"=>"The Octocat",
       "date"=>"2012-03-06T15:06:50-08:00",
       "email"=>"octocat@nowhere.com"},
     "url"=>
      "https://api.github.com/repos/octocat/Hello-World/git/commits/7fd1a60b01f91b314f59955a4e4d4e80d8edf11d",
     "message"=>
      "Shipped cool_feature!",
     "tree"=>
      {"sha"=>"b4eecafa9be2f2006ce1b709d6857b07069b4608",
       "url"=>
        "https://api.github.com/repos/octocat/Hello-World/git/trees/b4eecafa9be2f2006ce1b709d6857b07069b4608"},
     "committer"=>
      {"name"=>"The Octocat",
       "date"=>"2012-03-06T15:06:50-08:00",
       "email"=>"octocat@nowhere.com"}},
   "author"=>
    {"gravatar_id"=>"7ad39074b0584bc555d0417ae3e7d974",
     "avatar_url"=>
      "https://secure.gravatar.com/avatar/7ad39074b0584bc555d0417ae3e7d974?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png",
     "url"=>"https://api.github.com/users/octocat",
     "id"=>583231,
     "login"=>"octocat"},
   "parents"=>
    [{"sha"=>"553c2077f0edc3d5dc5d17262f6aa498e69d6f8e",
      "url"=>
       "https://api.github.com/repos/octocat/Hello-World/commits/553c2077f0edc3d5dc5d17262f6aa498e69d6f8e"},
     {"sha"=>"762941318ee16e59dabbacb1b4049eec22f0d303",
      "url"=>
       "https://api.github.com/repos/octocat/Hello-World/commits/762941318ee16e59dabbacb1b4049eec22f0d303"}],
   "url"=>
    "https://api.github.com/repos/octocat/Hello-World/commits/7fd1a60b01f91b314f59955a4e4d4e80d8edf11d",
   "committer"=>
    {"gravatar_id"=>"7ad39074b0584bc555d0417ae3e7d974",
     "avatar_url"=>
      "https://secure.gravatar.com/avatar/7ad39074b0584bc555d0417ae3e7d974?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png",
     "url"=>"https://api.github.com/users/octocat",
     "id"=>583231,
     "login"=>"octocat"}}}

    MILESTONE = {
      "url" => "https://api.github.com/repos/octocat/Hello-World/milestones/1",
      "number"        => 1,
      "state"         => "open",
      "title"         => "v1.0",
      "description"   => "",
      "creator"       => USER,
      "open_issues"   => 4,
      "closed_issues" => 8,
      "created_at"    => "2011-04-10T20:09:31Z",
      "due_on"        => nil
    }


    PULL = {
      "url"        => "https://api.github.com/octocat/Hello-World/pulls/1",
      "html_url"   => "https://github.com/octocat/Hello-World/pulls/1",
      "diff_url"   => "https://github.com/octocat/Hello-World/pulls/1.diff",
      "patch_url"  => "https://github.com/octocat/Hello-World/pulls/1.patch",
      "issue_url"  => "https://github.com/octocat/Hello-World/issue/1",
      "number"     => 1,
      "state"      => "open",
      "title"      => "new-feature",
      "body"       => "Please pull these awesome changes",
      "created_at" => "2011-01-26T19:01:12Z",
      "updated_at" => "2011-01-26T19:01:12Z",
      "closed_at"  => "2011-01-26T19:01:12Z",
      "merged_at"  => "2011-01-26T19:01:12Z",
      "head"          => {
        "label" => "new-topic",
        "ref"   => "new-topic",
        "sha"   => "6dcb09b5b57875f334f61aebed695e2e4193db5e",
        "user"  => USER,
        "repo"  => REPO,
      },
      "base"          => {
        "label" => "master",
        "ref"   => "master",
        "sha"   => "6dcb09b5b57875f334f61aebed695e2e4193db5e",
        "user"  => USER,
        "repo"  => REPO,
      },
      "_links" => {
        "self" => {'href' =>
          "https://api.github.com/octocat/Hello-World/pulls/1"},
        "html" => {'href' =>
          "https://github.com/octocat/Hello-World/pull/1"},
        "comments" => {'href' =>
          "https://api.github.com/octocat/Hello-World/issues/1/comments"},
        "review_comments" => {'href' =>
          "https://api.github.com/octocat/Hello-World/pulls/1/comments"}
      },
      "user" => USER
    }

    FULL_PULL = PULL.merge({
      "merged"        => false,
      "mergeable"     => true,
      "merged_by"     => USER,
      "comments"      => 10,
      "commits"       => 3,
      "additions"     => 100,
      "deletions"     => 3,
      "changed_files" => 5
    })

    COMMIT = {
      "url" => "https://api.github.com/repos/octocat/Hello-World/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "sha" => "6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "commit" => {
        "url" => "https://api.github.com/repos/octocat/Hello-World/git/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
        "sha" => "6dcb09b5b57875f334f61aebed695e2e4193db5e",
        "author" => {
           "name"  => "Monalisa Octocat",
           "email" => "support@github.com",
           "date"  => "2011-04-14T16:00:49Z",
        },
        "committer" => {
           "name"  => "Monalisa Octocat",
           "email" => "support@github.com",
           "date"  => "2011-04-14T16:00:49Z",
        },
        "message" => "Fix all the bugs",
        "tree" => {
          "url" => "https://api.github.com/repos/octocat/Hello-World/tree/6dcb09b5b57875f334f61aebed695e2e4193db5e",
          "sha" => "6dcb09b5b57875f334f61aebed695e2e4193db5e",
        },
      },
      "author" => USER,
      "committer" => USER,
      "parents" => [{
        "url" => "https://api.github.com/repos/octocat/Hello-World/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
        "sha" => "6dcb09b5b57875f334f61aebed695e2e4193db5e",
      }]
    }

    FULL_COMMIT = COMMIT.merge({
      "stats" => {
        "additions" => 104,
        "deletions" => 4,
        "total"     => 108,
      },
      "files" => [{
        "filename"  => "file1.txt",
        "additions" => 10,
        "deletions" => 2,
        "changes" => 12,
        "status" => "modified",
        "raw_url" => "https://github.com/octocat/Hello-World/raw/7ca483543807a51b6079e54ac4cc392bc29ae284/file1.txt",
        "blob_url" => "https://github.com/octocat/Hello-World/blob/7ca483543807a51b6079e54ac4cc392bc29ae284/file1.txt",
        "patch" => "@@ -29,7 +29,7 @@\n....."
      }]
    })

    COMMIT_COMMENT = {
      "html_url"   => "https://github.com/octocat/Hello-World/commit/6dcb09b5b57875f334f61aebed695e2e4193db5e#commitcomment-1",
      "url"        => "https://api.github.com/repos/octocat/Hello-World/comments/1",
      "id"         => 1,
      "body"       => "Great stuff",
      "path"       => "file1.txt",
      "position"   => 4,
      "line"       => 14,
      "commit_id"  => "6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "user"       => USER,
      "created_at" => "2011-04-14T16:00:49Z",
      "updated_at" => "2011-04-14T16:00:49Z"
    }

    FILE = {
      "sha"       => "6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "filename"  => "file1.txt",
      "status"    => "added",
      "additions" => 103,
      "deletions" => 21,
      "changes"   => 124,
      "blob_url"  => "https://github.com/octocat/Hello-World/blob/6dcb09b5b57875f334f61aebed695e2e4193db5e/file1.txt",
      "raw_url"   => "https://github.com/octocat/Hello-World/raw/6dcb09b5b57875f334f61aebed695e2e4193db5e/file1.txt",
      "patch"     => "@@ -132,7 +132,7 @@ module Test @@ -1000,7 +1000,7 @@ module Test"
    }

    COMMIT_COMPARISON = {
      "url" => "https://api.github.com/repos/octocat/Hello-World/compare/master...topic",
      "html_url" => "https://github.com/octocat/Hello-World/compare/master...topic",
      "permalink_url" => "https://github.com/octocat/Hello-World/compare/octocat:bbcd538c8e72b8c175046e27cc8f907076331401...octocat:0328041d1152db8ae77652d1618a02e57f745f17",
      "diff_url" => "https://github.com/octocat/Hello-World/compare/master...topic.diff",
      "patch_url" => "https://github.com/octocat/Hello-World/compare/master...topic.patch",
      "base_commit" => COMMIT,
      "status" => "behind",
      "ahead_by" => 1,
      "behind_by" => 2,
      "total_commits" => 1,
      "commits" => [COMMIT],
      "files" => [FILE],
    }

    PULL_COMMENT = {
      "url"        => "https://api.github.com/repos/octocat/Hello-World/pulls/comments/1",
      "id"         => 1,
      "body"       => "Great stuff",
      "path"       => "file1.txt",
      "position"   => 4,
      "commit_id"  => "6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "user"       => USER,
      "created_at" => "2011-04-14T16:00:49Z",
      "updated_at" => "2011-04-14T16:00:49Z",
      "_links" => {
        "self" => {'href' =>
          "https://api.github.com/octocat/Hello-World/pulls/comments/1"},
        "html" => {'href' =>
          "https://github.com/octocat/Hello-World/pull/1#discussion-diff-1"},
        "pull_request" => {'href' =>
          "https://api.github.com/octocat/Hello-World/pulls/1"}
      }
    }

    DOWNLOAD = {
      "url"            => "https://api.github.com/repos/octocat/Hello-World/downloads/1",
      "html_url"       => "https://github.com/repos/octocat/Hello-World/downloads/new_file.jpg",
      "id"             => 1,
      "name"           => "new_file.jpg",
      "description"    => "Description of your download",
      "size"           => 1024,
      "download_count" => 40,
      "content_type"   => ".jpg"
    }

    CREATE_DOWNLOAD = DOWNLOAD.merge({
      "policy"         => "ewogICAg...",
      "signature"      => "mwnFDC...",
      "bucket"         => "github",
      "accesskeyid"    => "1ABCDEFG...",
      "path"           => "downloads/ocotocat/Hello-World/new_file.jpg",
      "acl"            => "public-read",
      "expirationdate" => "2011-04-14T16:00:49Z",
      "prefix"         => "downloads/octocat/Hello-World/",
      "mime_type"      => "image/jpeg",
      "redirect"       => false,
      "s3_url"         => "https://github.s3.amazonaws.com/"
    })

    ORG = {
      "login"      => "github",
      "id"         => 1,
      "url"        => "https://api.github.com/orgs/github",
      "avatar_url" => "https://github.com/images/error/octocat_happy.gif"
    }

    FULL_ORG = ORG.merge({
      "name"         => "github",
      "company"      => "GitHub",
      "blog"         => "https://github.com/blog",
      "location"     => "San Francisco",
      "email"        => "octocat@github.com",
      "public_repos" => 2,
      "public_gists" => 1,
      "followers"    => 20,
      "following"    => 0,
      "html_url"     => "https://github.com/octocat",
      "created_at"   => "2008-01-14T04:33:35Z",
      "type"         => "Organization"
    })

    PRIVATE_ORG = FULL_ORG.merge({
      "total_private_repos" => 100,
      "owned_private_repos" => 100,
      "private_gists"       => 81,
      "disk_usage"          => 10000,
      "collaborators"       => 8,
      "billing_email"       => "support@github.com",
      "plan"                => {
        "name"          => "Medium",
        "space"         => 400,
        "private_repos" => 20
      }
    })

    TEAM = {
      "url" => "https://api.github.com/teams/1",
      "name" => "Owners",
      "id" => 1
    }

    FULL_TEAM = TEAM.merge({
      "permission" => "admin",
      "members_count" => 3,
      "repos_count" => 10
    })

    LABEL = {
      "url"   => "https://api.github.com/repos/octocat/Hello-World/labels/bug",
      "name"  => "bug",
      "color" => "f29513"
    }

    ISSUE = {
      "url"        => "https://api.github.com/repos/octocat/Hello-World/issues/1",
      "html_url"   => "https://github.com/octocat/Hello-World/issues/1",
      "number"     => 1347,
      "state"      => "open",
      "title"      => "Found a bug",
      "body"       => "I'm having a problem with this.",
      "user"       => USER,
      "labels"     => [LABEL],
      "assignee"   => USER,
      "milestone"  => MILESTONE,
      "comments"   => 0,
      "pull_request" => {
        "html_url"  => "https://github.com/octocat/Hello-World/issues/1",
        "diff_url"  => "https://github.com/octocat/Hello-World/issues/1.diff",
        "patch_url" => "https://github.com/octocat/Hello-World/issues/1.patch"
      },
      "closed_at"  => nil,
      "created_at" => "2011-04-22T13:33:48Z",
      "updated_at" => "2011-04-22T13:33:48Z"
    }

    ISSUE_COMMENT = {
      "id"         => 1,
      "url"        => "https://api.github.com/repos/octocat/Hello-World/issues/comments/1",
      "body"       => "Me too",
      "user"       => USER,
      "created_at" => "2011-04-14T16:00:49Z",
      "updated_at" => "2011-04-14T16:00:49Z"
    }

    ISSUE_EVENT = {
      "url" => "https://api.github.com/repos/octocat/Hello-World/issues/events/1",
      "actor"      => USER,
      "event"      => "closed",
      "commit_id"  => "6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "created_at" => "2011-04-14T16:00:49Z"
    }

    FULL_ISSUE_EVENT = ISSUE_EVENT.merge('issue' => ISSUE)

    ISSUE_SEARCH_ITEM = {
      "gravatar_id" =>  "4c3d600867886124a73f14a907b1a955",
      "position" =>  10,
      "number" =>  10,
      "votes" =>  2,
      "created_at" =>  "2010-06-04T23:20:33-07:00",
      "comments" =>  5,
      "body" =>  "Issue body goes here",
      "title" =>  "This is is the issue title",
      "updated_at" =>  "2010-06-04T23:20:33-07:00",
      "html_url" =>  "https://github.com/pengwynn/linkedin/issues/10",
      "user" =>  "ckarbass",
      "labels" =>  [
        "api",
        "feature request",
        "investigation"
      ],
      "state" =>  "open"
    }

    ISSUE_SEARCH_RESULTS = {
      "issues" => [ISSUE_SEARCH_ITEM]
    }

    REPO_SEARCH_ITEM = {
      "type" => "repo",
      "created" => "2011-09-05T11:07:54-07:00",
      "watchers" => 2913,
      "has_downloads" => true,
      "username" => "mathiasbynens",
      "homepage" => "http://mths.be/dotfiles",
      "url" => "https://github.com/mathiasbynens/dotfiles",
      "fork" => false,
      "has_issues" => true,
      "has_wiki" => false,
      "forks" => 520,
      "size" => 192,
      "private" => false,
      "followers" => 2913,
      "name" => "dotfiles",
      "owner" => "mathiasbynens",
      "open_issues" => 12,
      "pushed_at" => "2012-06-05T03:37:13-07:00",
      "score" => 3.289718,
      "pushed" => "2012-06-05T03:37:13-07:00",
      "description" => "sensible hacker defaults for OS X",
      "language" => "VimL",
      "created_at" => "2011-09-05T11:07:54-07:00"
    }

    REPO_SEARCH_RESULTS = {
      "repositories" => [REPO_SEARCH_ITEM]
    }

    USER_SEARCH_ITEM = {
      "gravatar_id" => "70889091349f7598bce9afa588034310",
      "name" => "Hirotaka Kawata",
      "created_at" => "2009-10-05T01:32:06Z",
      "location" => "Tsukuba, Ibaraki, Japan",
      "public_repo_count" => 8,
      "followers" => 10,
      "language" => "Python",
      "fullname" => "Hirotaka Kawata",
      "username" => "techno",
      "id" => "user-135050",
      "repos" => 8,
      "type" => "user",
      "followers_count" => 10,
      "pushed" => "2012-04-18T02:15:17.511Z",
      "login" => "techno",
      "score" => 4.2559967,
      "record" => nil,
      "created" => "2009-10-05T01:32:06Z"
    }

    USER_SEARCH_RESULTS = {
      "users" => [USER_SEARCH_ITEM]
    }

    EMAIL_SEARCH_RESULTS = {
      "user" => USER_SEARCH_ITEM
    }

    GIST_HISTORY = {
      "history" => [
        {
          "url"     => "https://api.github.com/gists/1/57a7f021a713b1c5a6a199b54cc514735d2d462f",
          "version" => "57a7f021a713b1c5a6a199b54cc514735d2d462f",
          "user"    => USER,
          "change_status" => {
            "deletions" => 0,
            "additions" => 180,
            "total"     => 180
          },
          "committed_at" => "2010-04-14T02:15:15Z"
        }
      ]
    }

    GIST_FORKS = {
      "forks" => [
        {
          "user" => USER,
          "url" => "https://api.github.com/gists/5",
          "created_at" => "2011-04-14T16:00:49Z"
        }
      ]
    }

    GIST_FILES = {
      "files" => {
        "ring.erl"   => {
          "size"     => 932,
          "filename" => "ring.erl",
          "raw_url"  => "https://gist.github.com/raw/365370/8c4d2d43d178df44f4c03a7f2ac0ff512853564e/ring.erl"
        }
      }
    }

    GIST = {
      "url"          => "https://api.github.com/gists/1",
      "id"           => "1",
      "description"  => "description of gist",
      "public"       => true,
      "user"         => USER,
      "files"        => GIST_FILES,
      "comments"     => 0,
      "html_url"     => "https://gist.github.com/1",
      "git_pull_url" => "git://gist.github.com/1.git",
      "git_push_url" => "git@gist.github.com:1.git",
      "created_at"   => "2010-04-14T02:15:15Z"
    }.update(GIST_FILES)

    FULL_GIST = GIST.merge(GIST_FORKS).merge(GIST_HISTORY)
    FULL_GIST['files']['ring.erl']['content'] = 'contents of gist'

    GIST_COMMENT = {
      "id"         => 1,
      "url"        => "https://api.github.com/gists/comments/1",
      "body"       => "Just commenting for the sake of commenting",
      "user"       => USER,
      "created_at" => "2011-04-18T23:23:56Z"
    }

    TREE = {
      "sha"  => "9fb037999f264ba9a7fc6274d15fa3ae2ab98312",
      "url"  => "https://api.github.com/repo/octocat/Hello-World/trees/9fb037999f264ba9a7fc6274d15fa3ae2ab98312",
      "tree"  => [
        { "path" => "file.rb",
          "mode" => "100644",
          "type" => "blob",
          "size" => 30,
          "sha"  => "44b4fc6d56897b048c772eb4087f854f46256132",
          "url"  => "https://api.github.com/octocat/Hello-World/git/blobs/44b4fc6d56897b048c772eb4087f854f46256132",
        },
        { "path" => "subdir",
          "mode" => "040000",
          "type" => "tree",
          "sha"  => "f484d249c660418515fb01c2b9662073663c242e",
          "url"  => "https://api.github.com/octocat/Hello-World/git/blobs/f484d249c660418515fb01c2b9662073663c242e"
        },
        { "path" => "exec_file",
          "mode" => "100755",
          "type" => "blob",
          "size" => 75,
          "sha"  => "45b983be36b73c0788dc9cbcb76cbb80fc7bb057",
          "url"  => "https://api.github.com/octocat/Hello-World/git/blobs/45b983be36b73c0788dc9cbcb76cbb80fc7bb057",
        }
      ]
    }
    TREE_EXTRA = {
      "sha"  => "fc6274d15fa3ae2ab983129fb037999f264ba9a7",
      "url"  => "https://api.github.com/repo/octocat/Hello-World/trees/fc6274d15fa3ae2ab983129fb037999f264ba9a7",
      "tree" => [ {
          "path" => "subdir/file.txt",
          "mode" => "100644",
          "type" => "blob",
          "size" => 132,
          "sha"  => "7c258a9869f33c1e1e1f74fbb32f07c86cb5a75b",
          "url"  => "https://api.github.com/octocat/Hello-World/git/7c258a9869f33c1e1e1f74fbb32f07c86cb5a75b"
      } ]
    }
    TREE_NEW = {
      "sha"  => "cd8274d15fa3ae2ab983129fb037999f264ba9a7",
      "url"  => "https://api.github.com/repo/octocat/Hello-World/trees/cd8274d15fa3ae2ab983129fb037999f264ba9a7",
      "tree" => [ {
          "path" => "file.rb",
          "mode" => "100644",
          "type" => "blob",
          "size" => 132,
          "sha"  => "7c258a9869f33c1e1e1f74fbb32f07c86cb5a75b",
          "url"  => "https://api.github.com/octocat/Hello-World/git/blobs/7c258a9869f33c1e1e1f74fbb32f07c86cb5a75b"
      } ]
    }

    GIT_COMMIT = {
      "sha" => "7638417db6d59f3c431d3e1f261cc637155684cd",
      "url" => "https://api.github.com/repos/octocat/Hello-World/git/commits/7638417db6d59f3c431d3e1f261cc637155684cd",
      "author" => {
        "date" => "2010-04-10T14:10:01-07:00",
        "name" => "Scott Chacon",
        "email" => "schacon@gmail.com"
      },
      "committer" => {
        "date" => "2010-04-10T14:10:01-07:00",
        "name" => "Scott Chacon",
        "email" => "schacon@gmail.com"
      },
      "message" => "added readme, because im a good github citizen\n",
      "tree" => {
        "url" => "https://api.github.com/repos/octocat/Hello-World/git/trees/691272480426f78a0138979dd3ce63b77f706feb",
        "sha" => "691272480426f78a0138979dd3ce63b77f706feb"
      },
      "parents" => [
        {
          "url" => "https://api.github.com/repos/octocat/Hello-World/git/commits/1acc419d4d6a9ce985db7be48c6349a0475975b5",
          "sha" => "1acc419d4d6a9ce985db7be48c6349a0475975b5"
        }
      ]
    }

    NEW_COMMIT = {
      "sha" => "7638417db6d59f3c431d3e1f261cc637155684cd",
      "url" => "https://api.github.com/repos/octocat/Hello-World/git/commits/7638417db6d59f3c431d3e1f261cc637155684cd",
      "author" => {
        "date" => "2008-07-09T16:13:30+12:00",
        "name" => "Scott Chacon",
        "email" => "schacon@gmail.com"
      },
      "committer" => {
        "date" => "2008-07-09T16:13:30+12:00",
        "name" => "Scott Chacon",
        "email" => "schacon@gmail.com"
      },
      "message" => "my commit message",
      "tree" => {
        "url" => "https://api.github.com/repos/octocat/Hello-World/git/trees/827efc6d56897b048c772eb4087f854f46256132",
        "sha" => "827efc6d56897b048c772eb4087f854f46256132"
      },
      "parents" => [
        {
          "url" => "https://api.github.com/repos/octocat/Hello-World/git/commits/7d1b31e74ee336d15cbd21741bc88a537ed063a0",
          "sha" => "7d1b31e74ee336d15cbd21741bc88a537ed063a0"
        }
      ]
    }

    GITTAG = {
      "tag" => "v0.0.1",
      "sha" => "940bd336248efae0f9ee5bc7b2d5c985887b16ac",
      "url" => "https://api.github.com/repos/octocat/Hello-World/git/tags/940bd336248efae0f9ee5bc7b2d5c985887b16ac",
      "message" => "initial version\n",
      "tagger" => {
        "name" => "Scott Chacon",
        "email" => "schacon@gmail.com",
        "date" => "2011-06-17T14:53:35-07:00"
      },
      "object" => {
        "type" => "commit",
        "sha" => "c3d0be41ecbe669545ee3e94d31ed9a4bc91ee3c",
        "url" => "https://api.github.com/repos/octocat/Hello-World/git/commits/c3d0be41ecbe669545ee3e94d31ed9a4bc91ee3c"
      }
    }

    REF = {
      "ref" => "refs/heads/sc/featureA",
      "url" => "https://api.github.com/repos/octocat/Hello-World/git/refs/heads/sc/featureA",
      "object" => {
        "type" => "commit",
        "sha" => "aa218f56b14c9653891f9e74264a383fa43fefbd",
        "url" => "https://api.github.com/repos/octocat/Hello-World/git/commits/aa218f56b14c9653891f9e74264a383fa43fefbd"
      }
    }

    REFS = [
      {
        "ref" => "refs/heads/master",
        "url" => "https://api.github.com/repos/octocat/Hello-World/git/refs/heads/master",
        "object" => {
          "type" => "commit",
          "sha" => "aa218f56b14c9653891f9e74264a383fa43fefbd",
          "url" => "https://api.github.com/repos/octocat/Hello-World/git/commits/aa218f56b14c9653891f9e74264a383fa43fefbd"
        }
      },
      {
        "ref" => "refs/heads/gh-pages",
        "url" => "https://api.github.com/repos/octocat/Hello-World/git/refs/heads/gh-pages",
        "object" => {
          "type" => "commit",
          "sha" => "612077ae6dffb4d2fbd8ce0cccaa58893b07b5ac",
          "url" => "https://api.github.com/repos/octocat/Hello-World/git/commits/612077ae6dffb4d2fbd8ce0cccaa58893b07b5ac"
        }
      },
      {
        "ref" => "refs/tags/v0.0.1",
        "url" => "https://api.github.com/repos/octocat/Hello-World/git/refs/tags/v0.0.1",
        "object" => {
          "type" => "tag",
          "sha" => "940bd336248efae0f9ee5bc7b2d5c985887b16ac",
          "url" => "https://api.github.com/repos/octocat/Hello-World/git/tags/940bd336248efae0f9ee5bc7b2d5c985887b16ac"
        }
      }
    ]

    HOOK = {
      "url" => "https://api.github.com/repos/octocat/Hello-World/hooks/1",
      "updated_at" => "2011-09-06T20:39:23Z",
      "created_at" => "2011-09-06T17:26:27Z",
      "name" => "web",
      "events" => ["push"],
      "active" => true,
      "config" =>
        {'url' => 'http://example.com', 'content_type' => 'json'},
      "id" => 1
    }

    OAUTH_ACCESS = {
      "id" => 1,
      "url" => "https://api.github.com/authorizations/1",
      "scopes" => ["public_repo"],
      "token" => "abc123",
      "app" => {
        "url" => "http://my-github-app.com",
        "name" => "my github app"
      },
      "note" => "optional note",
      "note_url" => "http://optional/note/url",
      "updated_at" => "2011-09-06T20:39:23Z",
      "created_at" => "2011-09-06T17:26:27Z"
    }

    EVENT = {
      :type   => "Event",
      :public => true,
      :payload => {},
      :repo => {
        :id => 3,
        :name => "octocat/Hello-World",
        :url => "https://api.github.com/repos/octocat/Hello-World"
      },
      :actor => USER,
      :org => USER,
      :created_at => "2011-09-06T17:26:27Z",
      :id => "12345"
    }

    README_CONTENT = {
      "type" =>  "file",
      "encoding" =>  "base64",
      "_links" =>  {
        "git" =>  "https://api.github.com/repos/pengwynn/octokit/git/blobs/3d21ec53a331a6f037a91c368710b99387d012c1",
        "self" =>  "https://api.github.com/repos/pengwynn/octokit/contents/README.md",
        "html" =>  "https://github.com/pengwynn/octokit/blob/master/README.md"
      },
      "size" =>  5362,
      "name" =>  "README.md",
      "path" =>  "README.md",
      "content" =>  "encoded content ...",
      "sha" =>  "3d21ec53a331a6f037a91c368710b99387d012c1"
    }

    STATUS = {
      "created_at" => "2012-07-20T01:19:13Z",
      "updated_at" => "2012-07-20T01:19:13Z",
      "state" => "success",
      "target_url" => "https://ci.example.com/1000/output",
      "description" => "Build has completed successfully",
      "id" => 1,
      "url" => "https://api.github.com/repos/octocat/example/statuses/1",
      "creator" => USER
    }

    BLOB = {
      :content => "Content of the blob",
      :encoding => "utf-8",
      :sha => "3a0f86fb8db8eea7ccbb9a95f325ddbedfb25e15",
      :size => 100
    }
  end
end

include GitHub::Resources::Helpers
