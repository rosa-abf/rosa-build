class ApplicationPresenter
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper

  def initialize(item, opts)
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
  end
end
