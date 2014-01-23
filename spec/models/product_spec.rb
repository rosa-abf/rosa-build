require 'spec_helper'

describe Product do
  let!(:product) { FactoryGirl.create(:product) }

  it { should belong_to(:platform) }
  it { should have_many(:product_build_lists)}

  it { should validate_presence_of(:name)}
  it { should validate_uniqueness_of(:name).scoped_to(:platform_id) }

  it { should ensure_length_of(:main_script).is_at_most(255) }
  it { should ensure_length_of(:params).is_at_most(255) }

  it { should have_readonly_attribute(:platform_id) }

  it { should_not allow_mass_assignment_of(:platform) }
  #it { should_not allow_mass_assignment_of(:platform_id) }
  it { should_not allow_mass_assignment_of(:product_build_lists) }


  context '#autostart_iso_builds' do

    Product::HUMAN_AUTOSTART_STATUSES.each do |autostart_status, human_autostart_status|
      it "new product_build_lists should not be created if no products which should be autostarted #{human_autostart_status}" do
        lambda { Product.autostart_iso_builds(autostart_status) }.should_not change{ ProductBuildList.count }
      end
    end

    context 'by autostart_status = once_a_12_hours' do
      before do
        stub_symlink_methods
        stub_redis
        params = {main_script: 'text.sh', project_version: product.project.default_branch}
        product.update_attributes params.merge(autostart_status: Product::ONCE_A_12_HOURS)
        FactoryGirl.create :product, params.merge(autostart_status: Product::ONCE_A_DAY)
      end

      it 'should be created only one product_build_list' do
        lambda { Product.autostart_iso_builds(Product::ONCE_A_12_HOURS) }.should change{ ProductBuildList.count }.by(1)
      end

      it 'product should has product_build_list' do
        Product.autostart_iso_builds Product::ONCE_A_12_HOURS
        product.product_build_lists.should have(1).item
      end

    end

  end

end
