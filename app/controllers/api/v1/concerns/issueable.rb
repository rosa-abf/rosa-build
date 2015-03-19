module Api
  module V1
    module Issueable
      extend ActiveSupport::Concern

      protected

      # Private: before_action hook which loads Group.
      def load_group
        authorize @group = Group.find(params[:id]), :show?
      end

      # Private: before_action hook which loads Project.
      def load_project
        authorize @project = Project.find(params[:project_id]), :show?
      end

      # Private: before_action hook which loads Issue.
      def load_issue
        authorize @issue = @project.issues.find_by(serial_id: params[:id]), :show?
      end

      # Private: Get membered projects.
      #
      # Returns the ActiveRecord::Relation instance.
      def membered_projects
        @membered_projects ||= ProjectPolicy::Scope.new(current_user, Project).membered
      end

      # Private: Get project ids which available for current user.
      #
      # Returns the Array of project ids.
      def get_all_project_ids(default_project_ids)
        project_ids = []
        if %w(created all).include? params[:filter]
          # add own issues
          project_ids = Project.opened.joins(:issues).
                                where(issues: {user_id: current_user.id}).
                                pluck('projects.id')
        end
        project_ids | default_project_ids
      end
    end
  end
end
