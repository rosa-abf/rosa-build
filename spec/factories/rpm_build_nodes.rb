FactoryGirl.define do
  factory :rpm_build_node do
    # id      { FactoryGirl.generate(:string) }
    user_id { FactoryGirl.create(:user).id }
    before(:build) do |n|
      n.send :id=, FactoryGirl.generate(:string)
    end
  end
end
