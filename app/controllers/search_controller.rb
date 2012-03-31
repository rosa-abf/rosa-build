# -*- encoding : utf-8 -*-
class SearchController < ApplicationController
  before_filter :authenticate_user! unless APP_CONFIG['anonymous_access']
  # load_and_authorize_resource

  def index
    params[:type] ||= 'all'
    params[:type] = 'projects' unless current_user
    case params[:type]
    when 'all'
      find_collection('projects')
      find_collection('users')
      find_collection('groups')
      find_collection('platforms')
    when 'projects', 'users', 'groups', 'platforms'
      find_collection(params[:type])
    end
  end

  protected

  def find_collection(type)
    var = :"@#{type}"
    instance_variable_set var, type.classify.constantize.opened.search(params[:query]).search_order.paginate(:page => params[:page]) unless instance_variable_defined?(var)
  end
end
