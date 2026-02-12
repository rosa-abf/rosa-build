# This code based on https://github.com/ihoka/viewtastic
module RosaPresenter
  module Activation
    def self.included(klass) # :nodoc:
      klass.prepend_before_action :activate_rosa_presenter # FIXME upgrade was before_filter
    end

    private
      def activate_rosa_presenter
        RosaPresenter::Base.controller = self
      end
  end
end
