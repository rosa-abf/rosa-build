require 'spec_helper'

describe KeyPair do
  it { should belong_to(:repository) }
  it { should belong_to(:user)}
  it { should validate_length_of(:public).is_at_most(10000) }
  it { should validate_length_of(:secret).is_at_most(10000) }

  describe 'check_keys validation' do
    subject { FactoryGirl.build(:key_pair) }

    it { expect(subject).to be_valid }

    it 'checks error when wrong public key' do
      subject.public =  'test'
      expect(subject).to_not be_valid
      expect(subject.errors[:public]).to contain_exactly I18n.t('activerecord.errors.key_pair.wrong_key')
    end

    it 'checks error when wrong secret key' do
      subject.secret =  'test'
      expect(subject).to_not be_valid
      expect(subject.errors[:secret]).to contain_exactly I18n.t('activerecord.errors.key_pair.wrong_key')
    end

    it 'checks error when public key contains secret key' do
      subject.public = subject.secret
      expect(subject).to_not be_valid
      expect(subject.errors[:public]).to contain_exactly I18n.t('activerecord.errors.key_pair.wrong_public_key')
    end

    it 'checks error when secret key contains public key' do
      subject.secret = subject.public
      expect(subject).to_not be_valid
      expect(subject.errors[:secret]).to contain_exactly I18n.t('activerecord.errors.key_pair.wrong_secret_key')
    end

    it 'checks error when different fingerprint of keys' do
      file = File.open(Rails.root.join('spec', 'support', 'fixtures', 'pubring.pass.gpg'), "rb")
      subject.public = file.read
      file.close
      expect(subject).to_not be_valid
      expect(subject.errors[:secret]).to contain_exactly I18n.t('activerecord.errors.key_pair.wrong_keys')
    end

    it 'checks error when secret key contains passphrase' do
      file = File.open(Rails.root.join('spec', 'support', 'fixtures', 'pubring.pass.gpg'), "rb")
      subject.public = file.read
      file.close
      file = File.open(Rails.root.join('spec', 'support', 'fixtures', 'secring.pass.gpg'), "rb")
      subject.secret = file.read
      file.close

      expect(subject).to_not be_valid
      expect(subject.errors[:secret]).to contain_exactly I18n.t('activerecord.errors.key_pair.key_has_passphrase')
    end

  end


  after(:all) do
    FileUtils.rm_rf(APP_CONFIG['root_path'])
  end
end
