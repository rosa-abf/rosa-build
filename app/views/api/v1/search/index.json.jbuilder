json.results do |json|
  @results.each do |tag, results|
    json.partial! tag.dup, :results => results, :json => json
  end
end
json.url api_v1_search_index_path(params)