json.partial! 'filter', issues: @issues

json.issues do
  json.partial! 'issues', issues: @issues
end
