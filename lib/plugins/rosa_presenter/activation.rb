# This code based on https://github.com/ihoka/viewtastic
module RosaPresenter
  module Activation
    def self.included(klass) # :nodoc:
      klass.prepend_before_filter :activate_rosa_presenter
    end

    private
      def activate_rosa_presenter
        RosaPresenter::Base.controller = self
      end
  end
end
