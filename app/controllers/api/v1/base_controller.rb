# -*- encoding : utf-8 -*-
class Api::V1::BaseController < ApplicationController
  before_filter :restrict_paginate, :only => :index

  protected

  def restrict_paginate
    params[:per_page] = 30  if params[:per_page].blank? or params[:per_page].to_i < 1
    params[:per_page] = 100 if params[:per_page].to_i >100
  end
end
