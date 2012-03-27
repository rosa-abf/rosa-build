# -*- encoding : utf-8 -*-
class UsersController < ApplicationController
  before_filter :authenticate_user!

  load_and_authorize_resource :only => :show
  before_filter :set_current_user, :only => [:profile, :update, :private]
  autocomplete :user, :uname

  def show
    @groups       = @user.groups.uniq
    @platforms   = @user.platforms.paginate(:page => params[:platform_page], :per_page => 10)
    @projects     = @user.projects.paginate(:page => params[:project_page], :per_page => 10)
  end

  def profile
  end

  def update
    send_confirmation = false
    if params[:user][:email] != @user.email
      send_confirmation = true
    end
    if @user.update_without_password(params[:user])
      if @user.avatar && params[:delete_avatar] == '1'
        @user.avatar = nil
        @user.save
      end
      if send_confirmation
        @user.confirmed_at = nil
        @user.confirmation_sent_at = nil
        @user.send_confirmation_instructions
      end
      flash[:notice] = t('flash.user.saved')
      redirect_to edit_profile_path
    else
      flash[:error] = t('flash.user.save_error')
      flash[:warning] = @user.errors.full_messages.join('. ')
      render(:action => :profile)
    end
  end

  def private
    if request.put?
      if @user.update_with_password(params[:user])
        flash[:notice] = t('flash.user.saved')
        redirect_to user_private_settings_path(@user)
      else
        flash[:error] = t('flash.user.save_error')
        flash[:warning] = @user.errors.full_messages.join('. ')
        render(:action => :private)
      end
    end
  end

  protected

  def set_current_user
    @user = current_user
  end

end
