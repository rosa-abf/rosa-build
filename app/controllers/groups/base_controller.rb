class Groups::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :find_group

  protected

  def find_group
    if group_id = params[:uname] || params[:group_id] || params[:id]
      @group = Group.find_by_insensitive_uname! group_id
    end
  end
end
