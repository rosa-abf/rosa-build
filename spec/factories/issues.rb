FactoryGirl.define do
  factory :issue do
    title { FactoryGirl.generate(:string) }
    body { FactoryGirl.generate(:string) }
    association :project, factory: :project
    association :user, factory: :user
    association :assignee, factory: :user
    status "open"
    # Hooks for #after_commit
    after(:create) { |i| i.send(:new_issue_notifications) }
    after(:create) { |i| i.send(:send_assign_notifications) }
    after(:create) { |i| i.send(:send_hooks) }
  end
end
