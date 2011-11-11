require 'spec_helper'

describe "product_build_lists/show.html.haml" do
  before(:each) do
    @product_build_list = assign(:product_build_list, stub_model(ProductBuildList,
      :product => nil,
      :status => "Status"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(//)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Status/)
  end
end
