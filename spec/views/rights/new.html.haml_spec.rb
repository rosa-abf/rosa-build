require 'spec_helper'

describe "rights/new.html.haml" do
  before(:each) do
    assign(:right, stub_model(Right,
      :controller_name => "MyString",
      :method_name => "MyString",
      :name => "MyString"
    ).as_new_record)
  end

  it "renders new right form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => rights_path, :method => "post" do
      assert_select "input#right_controller_name", :name => "right[controller_name]"
      assert_select "input#right_method_name", :name => "right[method_name]"
      assert_select "input#right_name", :name => "right[name]"
    end
  end
end
