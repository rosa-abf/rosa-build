require 'spec_helper'

describe "product_build_lists/index.html.haml" do
  before(:each) do
    assign(:product_build_lists, [
      stub_model(ProductBuildList,
        :product => nil,
        :status => "Status"
      ),
      stub_model(ProductBuildList,
        :product => nil,
        :status => "Status"
      )
    ])
  end

  it "renders a list of product_build_lists" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => nil.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Status".to_s, :count => 2
  end
end
