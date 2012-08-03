require 'spec_helper'

describe KeyPair do
  before(:all) do
    stub_symlink_methods
    stub_key_pairs_calls
    FactoryGirl.create(:key_pair)
  end

  it { should belong_to(:repository) }
  it { should belong_to(:user)}

  it { should_not allow_mass_assignment_of(:user) }
  it { should_not allow_mass_assignment_of(:key_id) }

  after(:all) do
    Platform.delete_all
    User.delete_all
    Product.delete_all
    FileUtils.rm_rf(APP_CONFIG['root_path'])
  end
end
