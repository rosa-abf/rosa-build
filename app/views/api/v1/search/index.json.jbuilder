json.results do
  @results.each do |tag, results|
    json.partial! tag.dup, results: results
  end
end
json.url api_v1_search_index_path(format: :json)