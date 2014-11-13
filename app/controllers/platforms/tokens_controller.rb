class Platforms::TokensController < Platforms::BaseController
  before_filter :authenticate_user!

  load_resource :platform
  load_and_authorize_resource :through  => :platform, :shallow  => true

  def index
    authorize! :local_admin_manage, @platform
    @tokens = @platform.tokens.includes(:creator, :updater)
                              .paginate(per_page: 20, page: params[:page])
  end

  def show
  end

  def withdraw
    if @token.block
      @token.updater = current_user
      @token.save
      redirect_to :back, notice: t('flash.tokens.withdraw_success')
    else
      redirect_to :back, notice: t('flash.tokens.withdraw_fail')
    end
  end

  def new
  end

  def create
    @token = @platform.tokens.build params[:token]
    @token.creator = current_user
    if @token.save
      flash[:notice] = t('flash.tokens.saved')
      redirect_to platform_tokens_path(@platform)
    else
      flash[:error] = t('flash.tokens.save_error')
      flash[:warning] = @token.errors.full_messages.join('. ') unless @token.errors.blank?
      render :new
    end
  end

end
