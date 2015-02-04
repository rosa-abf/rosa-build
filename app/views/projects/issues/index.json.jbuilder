json.partial! 'filter', issues: @issues

json.issues do
  json.partial! 'issues', issues: @issues
end

json.labels do
  all_issue_ids = @all_issues.not_closed_or_merged.pluck(:id)
  json.partial! 'labels', project: @project, all_issue_ids: all_issue_ids
end
