# -*- encoding : utf-8 -*-
class AdvisoriesController < ApplicationController
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user! if APP_CONFIG['anonymous_access']
  load_resource :find_by => :advisory_id
  authorize_resource

  def index
    @advisories = @advisories.scoped(:include => :platforms)
    @advisories = @advisories.search_by_id(params[:q]) if params[:q]
    @advisories = @advisories.paginate(:page => params[:page])
    respond_to do |format|
      format.html
      format.atom
    end
  end

  def show
    @packages_info = Hash.new { |h, k| h[k] = {} }
    @advisory.build_lists.find_in_batches(:include => [:save_to_platform, :packages, :project]) do |batch|
      batch.each do |build_list|
        h = { build_list.project => build_list.packages }
        @packages_info[build_list.save_to_platform].merge!(h) { |pr, old, new| (old + new).compact!.uniq! }
      end
    end
  end

  def search
    @advisory = Advisory.by_update_type(params[:bl_type]).search_by_id(params[:query]).first
    raise ActionController::RoutingError.new('Not Found') if @advisory.nil?
    respond_to do |format|
      format.json { render @advisory }
    end
  end

end
