json.pull_requests @pulls do |pull|
  json.partial! 'pull', pull: pull
end

json.url @pulls_url
