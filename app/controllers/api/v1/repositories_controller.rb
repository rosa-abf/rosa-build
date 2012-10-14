# -*- encoding : utf-8 -*-
class Api::V1::RepositoriesController < Api::V1::BaseController
  
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:show] if APP_CONFIG['anonymous_access']

  load_and_authorize_resource :repository, :through => :platform, :shallow => true

  def show
  end

  def update
    update_subject @repository
  end

  def add_member
    add_member_to_subject @repository
  end

  def remove_member
    remove_member_from_subject @repository
  end

  def destroy
    destroy_subject @repository
  end

end
