# -*- encoding : utf-8 -*-
module Modules
  module Controllers
    extend ActiveSupport::Autoload
  end

  module Models
    extend ActiveSupport::Autoload

    autoload :Owner
  end
end
