class Platforms::TokensController < Platforms::BaseController
  before_action :authenticate_user!

  before_action :load_token, except: [:index, :create, :new]

  def index
    authorize @platform, :local_admin_manage?
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
    authorize @token = @platform.tokens.new
  end

  def create
    @token = @platform.tokens.build token_params
    @token.creator = current_user
    authorize @token
    if @token.save
      flash[:notice] = t('flash.tokens.saved')
      redirect_to platform_tokens_path(@platform)
    else
      flash[:error] = t('flash.tokens.save_error')
      flash[:warning] = @token.errors.full_messages.join('. ') unless @token.errors.blank?
      render :new
    end
  end

  protected

  def token_params
    subject_params(Token)
  end

  # Private: before_action hook which loads Repository.
  def load_token
    authorize @token = @platform.tokens.find(params[:id])
  end

end
