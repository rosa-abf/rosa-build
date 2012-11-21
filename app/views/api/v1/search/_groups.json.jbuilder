json.groups results do |group|
  json.partial! 'member', :member => group, :json => json
end