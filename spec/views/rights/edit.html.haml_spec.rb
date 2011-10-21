require 'spec_helper'

describe "rights/edit.html.haml" do
  before(:each) do
    @right = assign(:right, stub_model(Right,
      :controller_name => "MyString",
      :method_name => "MyString",
      :name => "MyString"
    ))
  end

  it "renders the edit right form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => rights_path(@right), :method => "post" do
      assert_select "input#right_controller_name", :name => "right[controller_name]"
      assert_select "input#right_method_name", :name => "right[method_name]"
      assert_select "input#right_name", :name => "right[name]"
    end
  end
end
