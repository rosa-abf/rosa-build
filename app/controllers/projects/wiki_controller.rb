#require 'lib/gollum'
require 'cgi'

class Projects::WikiController < Projects::BaseController
  WIKI_OPTIONS = {}

  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:show, :index, :git, :compare, :compare_wiki, :history, :wiki_history, :search, :pages] if APP_CONFIG['anonymous_access']
  load_resource :project

  before_filter :authorize_read_actions,  :only => [:index, :show, :git, :compare, :compare_wiki, :history, :wiki_history, :search, :pages]
  before_filter :authorize_write_actions, :only => [:edit, :update, :new, :create, :destroy, :revert, :revert_wiki, :preview]
  before_filter :get_wiki

  def index
    @name = 'Home'
    @page = @wiki.page(@name)

    show_or_create_page
  end

  def show
    @name = CGI.unescape(params['id'])
    redirect_to project_wiki_index_path(@project) and return if @name == 'Home'

    ref = params['ref'] ? params['ref'] : @wiki.ref
    @page = @wiki.page(@name, ref)
    if !@page && @wiki.page(@name)
      flash[:error] = t('flash.wiki.ref_not_exist')
      redirect_to project_wiki_path(@project, CGI.escape(@name)) and return
    end

    show_or_create_page
  end

  def edit
    @name = CGI.unescape(params[:id])
    if page = @wiki.page(@name)
      @page = page
      @content = page.text_data
      render :edit
    else
      render :new
    end
  end

  def update
    @name = CGI.unescape(params[:id])
    @page = @wiki.page(@name)
    name = params[:rename] || @name

    update_wiki_page(@wiki, @page, params[:content], {:committer => committer}, name, params[:format])
    update_wiki_page(@wiki, @page.footer, params[:footer], {:committer => committer}) if params[:footer]
    update_wiki_page(@wiki, @page.sidebar, params[:sidebar], {:committer => committer}) if params[:sidebar]

    committer.commit

    flash[:notice] = t('flash.wiki.successfully_updated', :name => @name)
    redirect_to project_wiki_path(@project, CGI.escape(@name))
  end

  def new
    @name = ''
  end

  def create
    @name = CGI.unescape(params['page'])
    format = params['format'].intern
    begin
      @wiki.write_page(@name, format, params['content'] || '', {:committer => committer}).commit
      redirect_to project_wiki_path(@project, CGI.escape(@name))
    rescue Gollum::DuplicatePageError => e
      flash[:error] = t("flash.wiki.duplicate_page", :name => @name)
      render :action => :new
    end
  end

  def destroy
    @name = CGI.unescape(params[:id])
    page = @wiki.page(@name)
    if page
      @wiki.delete_page(page, {:committer => committer}).commit
      flash[:notice] = t("flash.wiki.page_successfully_removed")
    else
      flash[:notice] = t("flash.wiki.page_not_found", :name => params[:id])
    end
    redirect_to project_wiki_index_path(@project)
  end

  def git
  end

  def compare
    @name = CGI.unescape(params[:id])
    if request.post?
      @versions = params[:versions] || []
      if @versions.size < 2
        redirect_to history_project_wiki_path(@project, CGI.escape(@name))
      else
        redirect_to compare_versions_project_wiki_path(@project, CGI.escape(@name),
                                                       sprintf('%s...%s', @versions.last, @versions.first))
      end
    elsif request.get?
      @versions = params[:versions].split(/\.{2,3}/)
      if @versions.size < 2
        redirect_to history_project_wiki_path(@project, CGI.escape(@name))
        return
      end
      @page = @wiki.page(@name)
      @diffs = [@wiki.repo.diff(@versions.first, @versions.last, @page.path).first]
      render :compare
    else
      redirect_to project_wiki_path(@project, CGI.escape(@name))
    end
  end

  def compare_wiki
    if request.post?
      @versions = params[:versions] || []
      versions_string = case @versions.size
        when 1 then @versions.first
        when 2 then sprintf('%s...%s', @versions.last, @versions.first)
        else begin
          redirect_to history_project_wiki_index_path(@project)
          return
        end
      end
      redirect_to compare_versions_project_wiki_index_path(@project, versions_string)
    elsif request.get?
      @versions = params[:versions].split(/\.{2,3}/) || []
      @diffs = case @versions.size
        when 1 then @wiki.repo.commit_diff(@versions.first)
        when 2 then @wiki.repo.diff(@versions.first, @versions.last)
        else begin
          redirect_to history_project_wiki_index_path(@project)
          return
        end
      end
      render :compare
    else
      redirect_to project_wiki_path(@project, CGI.escape(@name))
    end
  end

  def revert
    @name = CGI.unescape(params[:id])
    @page = @wiki.page(@name)
    sha1  = params[:sha1]
    sha2  = params[:sha2]
    sha2  = nil if params[:sha2] == 'prev'

    if c = @wiki.revert_page(@page, sha1, sha2, {:committer => committer}) and c.commit
      flash[:notice] = t("flash.wiki.revert_success")
      redirect_to project_wiki_path(@project, CGI.escape(@name))
    else
      # if revert wasn't successful then redirect back to comparsion.
      # if second commit version is missed, then second version is 
      # params[:sha1] and first version is parent of params[:sha1]
      # (see Gollum::Wiki#revert_page)
      sha2, sha1 = sha1, "#{sha1}^" if !sha2
      @versions = [sha1, sha2]
      diffs     = @wiki.repo.diff(@versions.first, @versions.last, @page.path)
      @diffs    = [diffs.first]
      flash[:error]  = t("flash.wiki.patch_does_not_apply")
      render :compare
    end
  end

  def revert_wiki
    sha1 = params[:sha1]
    sha2 = params[:sha2]
    sha2 = nil if sha2 == 'prev'
    if c = @wiki.revert_commit(sha1, sha2, {:committer => committer}) and c.commit
      flash[:notice] = t("flash.wiki.revert_success")
      redirect_to project_wiki_index_path(@project)
    else
      sha2, sha1 = sha1, "#{sha1}^" if !sha2
      @versions = [sha1, sha2]
      @diffs     = @wiki.repo.diff(@versions.first, @versions.last)
      flash[:error] = t("flash.wiki.patch_does_not_apply")
      render :compare
    end
  end

  def preview
    @name = params['page']
    @page = @wiki.preview_page(@name, params['content'], params['format'])
    @content = @page.formatted_data
    @editable = false
    render :show
  end

  def history
    @name = CGI.unescape(params[:id])
    if @page = @wiki.page(@name)
      @versions = @page.versions
    else
      redirect_to :back
    end
  end

  def wiki_history
    @versions = @wiki.log
    render :history
  end

  def search
    @query = params[:q]
    @results = @wiki.search @query
  end

  def pages
    @results = @wiki.pages
    @ref = @wiki.ref
  end

  protected

    def get_wiki
      @wiki = Gollum::Wiki.new(@project.wiki_path,
               WIKI_OPTIONS.merge(:base_path => project_wiki_index_path(@project)))
    end

    # This method was grabbed from sinatra application, shipped with Gollum gem.
    # See Gollum gem and Gollum License if you have any questions about license notes.
    # https://github.com/github/gollum  https://github.com/github/gollum/blob/master/LICENSE
    def update_wiki_page(wiki, page, content, commit_msg, name = nil, format = nil)
      return if !page ||  
        ((!content || page.raw_data == content) && page.format == format)
      name    ||= page.name
      format    = (format || page.format).to_sym
      content ||= page.raw_data
      wiki.update_page(page, name, format, content.to_s, commit_msg)
    end

    def commit_message
      if params['message'] and !params['message'].empty?
        msg = params['message']
      else
        msg = case action_name.to_s
          when 'create'      then "Created page #{@name.to_s}"
          when 'update'      then "Updated page #{@name.to_s}"
          when 'destroy'     then "Removed page #{@name.to_s}"
          when 'revert'      then "Reverted page #{@name.to_s}"
          when 'revert_wiki' then "Reverted wiki"
        end
        msg << " (#{params['format']})" if params['format']
      end
      msg = 'Unhandled action' if !msg || msg.empty?
      { :message => msg }
    end

    def committer
      unless @committer
        p = commit_message.merge({:name => current_user.uname, :email => current_user.email})
        @committer = Gollum::Committer.new(@wiki, p)
        GitHook.perform_later!(:notification, :process, {:project_id => @project.id, :actor_name => @committer.actor.name, :commit_sha => @committer.commit})
      end
      @committer
    end

    def show_or_create_page
      if @page
        @content = @page.formatted_data
        @editable = can?(:write, @project)
        render :show
      elsif file = @wiki.file(@name)
        render :text => file.raw_data, :content_type => file.mime_type
      elsif can? :write, @project
        @new = true
        render :new
      else
        redirect_to :action => :index #forbidden_path
      end
    end

    def authorize_read_actions
      authorize! :show, @project
    end

    def authorize_write_actions
      authorize! :write, @project
    end
end

