# -*- encoding : utf-8 -*-
class ActivityFeedsController < ApplicationController
  before_filter :authenticate_user!

  def index
    @filter = t('feed_menu').has_key?(params[:filter].try(:to_sym)) ? params[:filter].to_sym : :all
    @activity_feeds = current_user.activity_feeds
    @activity_feeds = @activity_feeds.where(:kind => "ActivityFeed::#{@filter.upcase}".constantize) unless @filter == :all
    @activity_feeds = @activity_feeds.paginate :page => params[:page]
    if request.format == '*/*'
      render '_list', :layout => false
    else
      render 'index'
    end
  end
end
