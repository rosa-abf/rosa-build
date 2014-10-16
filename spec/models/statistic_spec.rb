require 'spec_helper'

describe Statistic do
  before { stub_symlink_methods }

  let(:statistic) { FactoryGirl.build(:statistic) }

  context 'ensures that validations and associations exist' do
    it { should belong_to(:project) }
    it { should belong_to(:user) }

    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:project_id) }
    it { should validate_presence_of(:project_name_with_owner) }
    it { should validate_presence_of(:key) }
    it { should validate_presence_of(:counter) }
    it { should validate_presence_of(:activity_at) }

    it 'rejects duplicates' do
      statistic.save
      duplicate = statistic.dup
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to eq ['has already been taken']
    end
  end

  context 'now_statsd_increment' do
    it 'ensures that not raises error' do
      lambda do
        2.times {
          Statistic.now_statsd_increment(
            user_id:                  statistic.user_id,
            project_id:               statistic.project_id,
            key:                      statistic.key,
            activity_at:              statistic.activity_at,
          )
        }
      end.should_not raise_exception
      expect(Statistic).to have(1).item
      expect(Statistic.first.counter).to eq 2
    end
  end

end
