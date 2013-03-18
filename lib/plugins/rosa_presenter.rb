module RosaPresenter
  extend ActiveSupport::Autoload

  autoload :Activation
  autoload :Base

  VERSION = "0.0.1"
end

ActionController::Base.send(:include, RosaPresenter::Activation)
