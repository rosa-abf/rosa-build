require 'xmlrpc/client'
module XMLRPC
  class Client
    def call(*args)
      # raise args.inspect
      case
      when args.first == 'get_status'
        {'client_count' => 1, 'count_new_task' => 2, 'count_build_task' => 3}
        # raise Timeout::Error
      else; 0
      end
    end
  end
end
