# -*- encoding : utf-8 -*-
class Api::V1::RepositoriesController < Api::V1::BaseController
  
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:show] if APP_CONFIG['anonymous_access']

  load_and_authorize_resource :repository, :through => :platform, :shallow => true

  def show

  end

end
