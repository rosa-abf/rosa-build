module Rosa
  module Constraints
    class Owner
      def initialize(class_name, bang = false)
        @class_name = class_name
        @finder = 'find_by_insensitive_uname'
        @finder << '!' if bang
      end

      def matches?(request)
        @class_name.send(@finder, request.params[:uname]).present?
      end
    end

    class AdminAccess
      def self.matches?(request)
        !!request.env['warden'].user.try(:admin?)
      end
    end

    class Treeish
      def self.matches?(request)
        if (params = request.path_parameters) && params[:treeish] # parse existing branch (tag) and path
          branch_or_tag = begin
            (p = Project.find_by_owner_and_name params[:owner_and_name]) &&
            p.repo.branches_and_tags.map(&:name).sort{|a,b| b.length <=> a.length}.detect{|b| params[:treeish].start_with?(b)} ||
            params[:treeish].split('/').first
          end
          if path = params[:treeish].sub(branch_or_tag, '')[1..-1] and path.present?
            params[:path] = File.join([path, params[:path]].compact)
          end
          params[:treeish] = branch_or_tag
        end
        true
      end
    end
  end
end
