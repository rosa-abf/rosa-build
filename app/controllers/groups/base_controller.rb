# -*- encoding : utf-8 -*-
class Groups::BaseController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_group

  protected

  def find_group
    if group_id = params[:owner_name] || params[:group_id] || params[:id]
      @group = Group.find_by_owner_name! group_id
    end
  end
end
