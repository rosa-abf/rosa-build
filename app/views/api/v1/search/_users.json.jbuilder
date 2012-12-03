json.users results do |user|
  json.partial! 'member', :member => user, :json => json
end