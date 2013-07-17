json.users results do |user|
  json.partial! 'member', :member => user
end