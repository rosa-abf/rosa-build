# -*- encoding : utf-8 -*-
class Users::RegisterRequestsController < ApplicationController
  def new
    redirect_to '/invite.html'
  end

  def create
    RegisterRequest.create(params[:register_request])
    redirect_to '/thanks.html'
  end
end
