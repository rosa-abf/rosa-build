require 'spec_helper'

describe "permissions/index.html.haml" do
  before(:each) do
    assign(:permissions, [
      stub_model(Permission,
        :role_id => 1,
        :right_id => 1,
        :access_obj_id => 1
      ),
      stub_model(Permission,
        :role_id => 1,
        :right_id => 1,
        :access_obj_id => 1
      )
    ])
  end

  it "renders a list of permissions" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
  end
end
