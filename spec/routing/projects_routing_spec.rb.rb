# -*- encoding : utf-8 -*-
require "spec_helper"

describe Projects::ProjectsController do
  describe "routing" do

    it "routes to #index" do
      get("/projects").should route_to("projects/projects#index")
    end

    it "routes to #new" do
      get("/projects/new").should route_to("projects/projects#new")
    end

    it "routes to #edit" do
      get("/import/glib2.0-mib/edit").should route_to("projects/projects#edit", :owner_name => 'import', :project_name => 'glib2.0-mib')
    end

    it "routes to #create" do
      post("/projects").should route_to("projects/projects#create")
    end

    it "routes to #update" do
      put("/import/glib2.0-mib").should route_to("projects/projects#update", :owner_name => 'import', :project_name => 'glib2.0-mib')
    end

    it "routes to #destroy" do
      delete("/import/glib2.0-mib").should route_to("projects/projects#destroy", :owner_name => 'import', :project_name => 'glib2.0-mib')
    end

  end
end

describe Projects::Git::TreesController do
  describe "routing" do

    it "routes to #show" do
      get("/import/glib2.0-mib").should route_to("projects/git/trees#show", :owner_name => 'import', :project_name => 'glib2.0-mib')
      get("/import/glib2.0-mib/tree/branch").should route_to("projects/git/trees#show", :owner_name => 'import', :project_name => 'glib2.0-mib', :treeish => 'branch')
      get("/import/glib2.0-mib/tree/branch/some/path.to").should route_to("projects/git/trees#show", :owner_name => 'import', :project_name => 'glib2.0-mib', :treeish => 'branch', :path => 'some/path.to')
    end

    # TODO write more specs also with slash in branch name!

  end
end
