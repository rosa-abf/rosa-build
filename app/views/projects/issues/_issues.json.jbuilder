json.array!(issues) do |issue|
  json.partial! 'projects/issues/issue.json', issue: issue
end
