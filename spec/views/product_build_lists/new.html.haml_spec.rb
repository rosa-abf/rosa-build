require 'spec_helper'

describe "product_build_lists/new.html.haml" do
  before(:each) do
    assign(:product_build_list, stub_model(ProductBuildList,
      :product => nil,
      :status => "MyString"
    ).as_new_record)
  end

  it "renders new product_build_list form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => product_build_lists_path, :method => "post" do
      assert_select "input#product_build_list_product", :name => "product_build_list[product]"
      assert_select "input#product_build_list_status", :name => "product_build_list[status]"
    end
  end
end
