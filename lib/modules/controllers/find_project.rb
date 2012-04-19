# -*- encoding : utf-8 -*-
module Modules
  module Controllers
    module FindProject
      extend ActiveSupport::Concern

      included do
        prepend_before_filter :find_project
      end

      protected

      def find_project
        @project = Project.find_by_owner_and_name!(params[:owner_name], params[:project_name]) if params[:owner_name] && params[:project_name]
      end

      module ClassMethods
      end
    end
  end
end
