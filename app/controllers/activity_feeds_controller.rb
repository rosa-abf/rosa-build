# -*- encoding : utf-8 -*-
class ActivityFeedsController < ApplicationController
  before_filter :custom_authenticate!

  def index
    @filter = t('feed_menu').has_key?(params[:filter].try(:to_sym)) ? params[:filter].to_sym : :all
    @activity_feeds = @user.activity_feeds
    @activity_feeds = @activity_feeds.where(:kind => "ActivityFeed::#{@filter.upcase}".constantize) unless @filter == :all
    @activity_feeds = @activity_feeds.paginate :page => params[:page]
    respond_to do |format|
      format.html { request.xhr? ? render('_list', :layout => false) : render('index') }
      format.atom
    end
  end

  private

  def custom_authenticate!
    if params[:token]
      @user = User.find_by_authentication_token params[:token]
      redirect_to(new_user_session_path) unless @user.present?
    else
      @user = current_user if authenticate_user!
    end
  end
end
