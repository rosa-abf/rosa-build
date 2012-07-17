# -*- encoding : utf-8 -*-
class OwnerConstraint
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

class TreeishConstraint
  def self.matches?(request)
    # raise request.params.inspect
    # params = request.env['action_dispatch.request.path_parameters'] || request.params
    params = request.path_parameters
    if params[:treeish] # parse existing branch (tag) and path
      branch_or_tag = begin
        (p = Project.find_by_owner_and_name params[:owner_name], params[:project_name]) &&
        (p.repo.branches + p.repo.tags).detect{|t| params[:treeish].start_with?(t.name)}.try(:name) ||
        params[:treeish].split('/').first
      end
      if path = params[:treeish].sub(branch_or_tag, '')[1..-1] and path.present?
        params[:path] = File.join([path, params[:path]].compact)
      end
      params[:treeish] = branch_or_tag
    end
    true
  end

  # def set_treeish_and_path
  #   if params[:treeish] and params[:path] and # try to correct branch with slashes
  #      treeish_with_path = File.join(params[:treeish], params[:path]) and
  #      branch_name = @project.repo.branches.detect{|t| treeish_with_path.start_with?(t.name)}.try(:name)
  #     params[:treeish] = branch_name
  #     params[:path] = treeish_with_path.sub(branch_name, '')[1..-1]
  #   end
  #   @treeish = params[:treeish].presence || @project.default_branch
  #   @path = params[:path]
  # end  
end
