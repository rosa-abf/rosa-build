# -*- encoding : utf-8 -*-
require Rails.root.join('lib/rails_datatables/rails_datatables')
ActionView::Base.send :include, RailsDatatables
