# -*- encoding : utf-8 -*-
class AdvisoriesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_advisory, :only => [:show]
  skip_before_filter :authenticate_user! if APP_CONFIG['anonymous_access']
  load_and_authorize_resource

  def index
    @advisories = @advisories.paginate(:page => params[:page])
  end

  def show
  end

  protected

  def find_advisory
    @advisory = Advisory.where(:advisory_id => params[:id]).limit(1).first if params[:id].present?
  end
end
