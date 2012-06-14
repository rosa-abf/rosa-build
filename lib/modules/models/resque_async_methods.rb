# -*- encoding : utf-8 -*-
module Modules
  module Models
    module ResqueAsyncMethods
      extend ActiveSupport::Concern

      included do
        # We can pass this any Repository instance method that we want to
        # run later.
        def async(method, *args)
          Resque.enqueue(self.class, id, method, *args)
        end
      end

      module ClassMethods
        # This will be called by a worker when a job needs to be processed
        def perform(id, method, *args)
          unless id.nil?
            find(id).send(method, *args)
          else
            send(method, *args)
          end
        end

        def async(method, *args)
          Resque.enqueue(self, nil, method, *args)
        end
      end
    end
  end
end

