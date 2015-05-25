require 'spec_helper'

describe Product do
  let(:product) { FactoryGirl.create(:product) }
  before { stub_symlink_methods }

  context 'ensures that validations and associations exist' do

    it 'is valid given valid attributes' do
      # arch = FactoryGirl.create(:arch, name: 'x86_64')
      # allow(Arch).to receive(:find_by).with(name: 'x86_64').and_return(arch)
      FactoryGirl.create(:product).should be_truthy
    end

    it { should belong_to(:platform) }
    it { should have_many(:product_build_lists)}

    it { should validate_presence_of(:name)}

    context 'uniqueness' do
      before { product }
      it { should validate_uniqueness_of(:name).scoped_to(:platform_id) }
    end

    it { should validate_length_of(:main_script).is_at_most(255) }
    it { should validate_length_of(:params).is_at_most(255) }

    it { should have_readonly_attribute(:platform_id) }
  end


  context '#autostart_iso_builds' do
    before { product }

    Product::HUMAN_AUTOSTART_STATUSES.each do |autostart_status, human_autostart_status|
      it "new product_build_lists should not be created if no products which should be autostarted #{human_autostart_status}" do
        lambda { Product.autostart_iso_builds(autostart_status) }.should_not change{ ProductBuildList.count }
      end
    end

    context 'by autostart_status = once_a_12_hours' do
      before do
        stub_symlink_methods
        params = {main_script: 'text.sh', project_version: product.project.default_branch}
        product.update_attributes params.merge(autostart_status: Product::ONCE_A_12_HOURS)
        FactoryGirl.create :product, params.merge(autostart_status: Product::ONCE_A_DAY)
        FactoryGirl.create(:arch, name: 'x86_64')
      end

      it 'should be created only one product_build_list' do
        lambda { Product.autostart_iso_builds(Product::ONCE_A_12_HOURS) }.should change{ ProductBuildList.count }.by(1)
      end

      it 'product should has product_build_list' do
        Product.autostart_iso_builds Product::ONCE_A_12_HOURS
        expect(product.product_build_lists.count).to eq 1
      end

    end

  end

end
