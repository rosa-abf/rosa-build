# -*- encoding : utf-8 -*-
class Api::V1::RepositoriesController < Api::V1::BaseController
  #before_filter :authenticate_user!

  load_and_authorize_resource :repository, :through => :platform, :shallow => true
end
