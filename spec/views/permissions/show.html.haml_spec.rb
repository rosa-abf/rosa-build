require 'spec_helper'

describe "permissions/show.html.haml" do
  before(:each) do
    @permission = assign(:permission, stub_model(Permission,
      :role_id => 1,
      :right_id => 1,
      :access_obj_id => 1
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
  end
end
