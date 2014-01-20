FactoryGirl.define do
  factory :hook do
    name 'web'
    association :project, :factory => :project
    data { |hook| hook.data = {:url => 'url'} }
  end
end
