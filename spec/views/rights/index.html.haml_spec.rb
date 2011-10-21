require 'spec_helper'

describe "rights/index.html.haml" do
  before(:each) do
    assign(:rights, [
      stub_model(Right,
        :controller_name => "Controller Name",
        :method_name => "Method Name",
        :name => "Name"
      ),
      stub_model(Right,
        :controller_name => "Controller Name",
        :method_name => "Method Name",
        :name => "Name"
      )
    ])
  end

  it "renders a list of rights" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Controller Name".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Method Name".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
  end
end
