require 'spec_helper'

describe "rights/show.html.haml" do
  before(:each) do
    @right = assign(:right, stub_model(Right,
      :controller_name => "Controller Name",
      :method_name => "Method Name",
      :name => "Name"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Controller Name/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Method Name/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
  end
end
