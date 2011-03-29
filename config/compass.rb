# This configuration file works with both the Compass command line tool and within Rails.
require 'html5-boilerplate'
# Require any additional compass plugins here.

project_type = :rails
project_path = Compass::AppIntegration::Rails.root
environment = Compass::AppIntegration::Rails.env

# Set this to the root of your project when deployed:
http_path = "/"
css_dir = "public/stylesheets/compiled"
sass_dir = "app/stylesheets"
javascripts_dir = "public/javascripts"

http_stylesheets_path = "/stylesheets"
http_javascripts_path = "/javascripts"