# class ParamsParser
#   DEFAULT_PARSERS = {
#     Mime::XML => :xml_simple,
#     Mime::JSON => :json
#   }
# 
#   def initialize(app, parsers = {})
#     @app, @parsers = app, DEFAULT_PARSERS.merge(parsers)
#   end
# 
#   def call(env)
#     if params = parse_formatted_parameters(env)
#       env["action_dispatch.request.request_parameters"] = params
#     end
# 
#     @app.call(env)
#   end
# end
