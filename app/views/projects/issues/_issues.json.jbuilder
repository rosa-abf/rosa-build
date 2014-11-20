json.array!(issues) do |issue|
  json.partial! 'issue.json', issue: issue
end
