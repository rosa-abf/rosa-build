# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :register_request do
      name "MyString"
      email "MyString"
      token "MyString"
      approved false
    end
end
