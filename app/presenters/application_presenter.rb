class ApplicationPresenter < RosaPresenter::Base
end

#class ApplicationPresenter
#  include ActionDispatch::Routing::UrlFor
#  include ActionView::Helpers::UrlHelper
#  include Rails.application.routes.url_helpers
#
#  attr_accessor :controller
#
#  def initialize(item, opts)
#  end
#
#  # TODO it needs to be refactored!
#  class << self
#    def present(item, opts, &block)
#      block.call(self.new(item, opts))
#    end
#
#    def present_collection(collection, &block)
#      res = collection.map {|e| self.new(*e)}
#      if block.present?
#        res = res.inject('') do |akk, presenter|
#          akk << block.call(presenter)
#          akk
#        end
#      end
#      return res
#    end
#  end
#
#  protected
#
#  def t(*args)
#    I18n.translate(*args)
#  end
#
#  def l(*args)
#    I18n.localize(*args)
#  end
#end
#
#module Presenters
#  module Activation
#    def self.included(klass) # :nodoc:
#      klass.prepend_before_filter :activate_presenter
#    end
#
#    private
#      def activate_presenter
#        ApplicationPresenter.controller = self
#      end
#  end
#end
#ActionController::Base.send(:include, Presenters::Activation)
