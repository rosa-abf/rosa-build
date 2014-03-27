# This code based on https://github.com/ihoka/viewtastic
module RosaPresenter
  class Base
    # include ActionDispatch::Routing::UrlFor
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::OutputSafetyHelper
    include ActionView::Helpers::JavaScriptHelper
    include Rails.application.routes.url_helpers

    def initialize(item, opts)
    end

    def controller
      Thread.current[:rosa_presenter_controller]
    end

    def helpers
      controller.view_context
    end

    # TODO it needs to be refactored!
    class << self
      def present(item, opts, &block)
        block.call(self.new(item, opts))
      end

      def present_collection(collection, &block)
        res = collection.map {|e| self.new(*e)}
        if block.present?
          res = res.inject('') do |akk, presenter|
            akk << block.call(presenter)
            akk
          end
        end
        return res
      end

      def controller=(value) #:nodoc:
        Thread.current[:rosa_presenter_controller] = value
      end

      def controller #:nodoc:
        Thread.current[:rosa_presenter_controller]
      end

      def activated? #:nodoc:
        !controller.nil?
      end
    end

    protected

    def t(*args)
      I18n.translate(*args)
    end

    def l(*args)
      I18n.localize(*args)
    end
  end
end
