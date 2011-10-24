require "spec_helper"

describe RightsController do
  describe "routing" do

    it "routes to #index" do
      get("/rights").should route_to("rights#index")
    end

    it "routes to #new" do
      get("/rights/new").should route_to("rights#new")
    end

    it "routes to #show" do
      get("/rights/1").should route_to("rights#show", :id => "1")
    end

    it "routes to #edit" do
      get("/rights/1/edit").should route_to("rights#edit", :id => "1")
    end

    it "routes to #create" do
      post("/rights").should route_to("rights#create")
    end

    it "routes to #update" do
      put("/rights/1").should route_to("rights#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/rights/1").should route_to("rights#destroy", :id => "1")
    end

  end
end
