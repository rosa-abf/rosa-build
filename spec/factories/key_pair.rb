FactoryGirl.define do
  factory :key_pair do
    association :repository
    association :user
    public {
      file = File.open(Rails.root.join('spec', 'support', 'fixtures', 'pubring.gpg'), "rb")
      contents = file.read
      file.close
      contents
    }
    secret {
      file = File.open(Rails.root.join('spec', 'support', 'fixtures', 'secring.gpg'), "rb")
      contents = file.read
      file.close
      contents
    }
  end
end

