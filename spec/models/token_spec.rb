require 'spec_helper'

describe Token do
  before { stub_symlink_methods }

  describe 'platform token' do
    let!(:platform_token) { FactoryGirl.create(:platform_token) }

    context 'ensures that validations and associations exist' do
      it { should belong_to(:subject) }
      it { should belong_to(:creator) }

      it { should validate_presence_of(:creator_id) }
      it { should validate_presence_of(:subject_id) }
      it { should validate_presence_of(:subject_type) }

      it 'ensures that authentication_token unique' do
        token = FactoryGirl.create(:platform_token)
        token.authentication_token = platform_token.authentication_token
        token.valid?.should be_falsy
      end
    end
  end


end
