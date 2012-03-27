# -*- encoding : utf-8 -*-
#require "whenever/capistrano"
set :branch, "master"

set :domain, "89.248.225.78" # "195.19.76.12"
set :port, 16922

role :app, domain
role :web, domain
role :db,  domain, :primary => true

#set :application, "rosa_build_#{stage}"
#set :deploy_to, "/srv/#{application}"
#before "deploy:restart", "deploy:stub_xml_rpc"
