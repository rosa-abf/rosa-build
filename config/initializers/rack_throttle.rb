#class Rack::Throttle::Limiter
#  def http_error(code, message = nil, headers = {})
#    [code, {'Content-Type' => 'application/json; charset=utf-8'}.merge(headers),
#     Array(({'message' => http_status(code) + " | " + message}.to_json))]
#  end
#end

