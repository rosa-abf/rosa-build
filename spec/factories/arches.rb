FactoryGirl.define do
  factory :arch do
    name { FactoryGirl.generate(:unixname) }
  end
end
