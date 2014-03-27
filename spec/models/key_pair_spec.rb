require 'spec_helper'

describe KeyPair do
  before(:all) { FactoryGirl.create(:key_pair) }

  it { should belong_to(:repository) }
  it { should belong_to(:user)}
  it { should ensure_length_of(:public).is_at_most(10000) }
  it { should ensure_length_of(:secret).is_at_most(10000) }


  it { should_not allow_mass_assignment_of(:user) }
  it { should_not allow_mass_assignment_of(:key_id) }

  describe 'check_keys validation' do
    subject { FactoryGirl.build(:key_pair) }

    it { subject.valid?.should be_true }
    it 'checks error when wrong public key' do
      subject.public =  'test'
      subject.valid?
      subject.errors[:public].should =~ [I18n.t('activerecord.errors.key_pair.wrong_key')]
    end

    it 'checks error when wrong secret key' do
      subject.secret =  'test'
      subject.valid?
      subject.errors[:secret].should =~ [I18n.t('activerecord.errors.key_pair.wrong_key')]
    end

    it 'checks error when public key contains secret key' do
      subject.public = subject.secret
      subject.valid?
      subject.errors[:public].should =~ [I18n.t('activerecord.errors.key_pair.wrong_public_key')]
    end

    it 'checks error when secret key contains public key' do
      subject.secret = subject.public
      subject.valid?
      subject.errors[:secret].should =~ [I18n.t('activerecord.errors.key_pair.wrong_secret_key')]
    end

    it 'checks error when different fingerprint of keys' do
      file = File.open(Rails.root.join('spec', 'support', 'fixtures', 'pubring.pass.gpg'), "rb")
      subject.public = file.read
      file.close
      subject.valid?
      subject.errors[:secret].should =~ [I18n.t('activerecord.errors.key_pair.wrong_keys')]
    end

    it 'checks error when secret key contains passphrase' do
      file = File.open(Rails.root.join('spec', 'support', 'fixtures', 'pubring.pass.gpg'), "rb")
      subject.public = file.read
      file.close
      file = File.open(Rails.root.join('spec', 'support', 'fixtures', 'secring.pass.gpg'), "rb")
      subject.secret = file.read
      file.close

      subject.valid?
      subject.errors[:secret].should =~ [I18n.t('activerecord.errors.key_pair.key_has_passphrase')]
    end

  end


  after(:all) do
    Platform.delete_all
    User.delete_all
    Product.delete_all
    FileUtils.rm_rf(APP_CONFIG['root_path'])
  end
end
