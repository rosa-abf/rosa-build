# -*- encoding : utf-8 -*-
class PagesController < ApplicationController
  # before_filter :authenticate_user!, :except => [:show, :main, :forbidden]
  # load_and_authorize_resource

  def root
  end

  def forbidden
  end

  def tos
  end
end
