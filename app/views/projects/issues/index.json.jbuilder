json.total_items @issues.count
json.issues do
  json.partial! 'issues', issues: @issues
end
