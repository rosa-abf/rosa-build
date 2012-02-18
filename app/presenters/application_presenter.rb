class ApplicationPresenter
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper

  def initialize(*args)
  end

  # TODO it needs to be refactored!
  class << self
    def present(*args, &block)
      block.call(self.new(*args))
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
