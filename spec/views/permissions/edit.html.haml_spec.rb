require 'spec_helper'

describe "permissions/edit.html.haml" do
  before(:each) do
    @permission = assign(:permission, stub_model(Permission,
      :role_id => 1,
      :right_id => 1,
      :access_obj_id => 1
    ))
  end

  it "renders the edit permission form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => permissions_path(@permission), :method => "post" do
      assert_select "input#permission_role_id", :name => "permission[role_id]"
      assert_select "input#permission_right_id", :name => "permission[right_id]"
      assert_select "input#permission_access_obj_id", :name => "permission[access_obj_id]"
    end
  end
end
