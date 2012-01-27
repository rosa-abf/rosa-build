require 'lib/gollum'
require 'cgi'

class WikiController < ApplicationController
  WIKI_OPTIONS = {}

  load_resource :project

  before_filter :get_wiki

  def index
    if can? :read, @project
      @name = 'Home'
      @page = @wiki.page(@name)

      show_or_create_page
    else
      redirect_to forbidden_path
    end
  end

  def show
    if can? :read, @project
      @name = params['id']
      redirect_to project_wiki_index_path(@project) and return if @name == 'Home'

      ref = params['ref'] ? params['ref'] : @wiki.ref
      @page = @wiki.page(@name, ref)
      if !@page && @wiki.page(@name)
        flash[:error] = t('flash.wiki.ref_not_exist')
        redirect_to project_wiki_path(@project, CGI.escape(@name)) and return
      end

      show_or_create_page
    else
      redirect_to forbidden_path
    end
  end

  def edit
    if can? :update, @project
      @name = params[:id]
      if page = @wiki.page(@name)
        @page = page
        @content = page.raw_data
        render :edit
      else
        render :new
      end
    else
      redirect_to forbidden_path
    end
  end

  def update
    if can? :update, @project
      @name = params[:id]
      page = @wiki.page(@name)
      name = params[:rename] || @name
      committer = Gollum::Committer.new(@wiki, commit)
      commit = {:committer => committer}

      update_wiki_page(@wiki, page, params[:content], commit, name, params[:format])
      update_wiki_page(@wiki, page.footer, params[:footer], commit) if params[:footer]
      update_wiki_page(@wiki, page.sidebar, params[:sidebar], commit) if params[:sidebar]

      committer.commit

      flash[:notice] = t('flash.wiki.successfully_updated', :name => @name)
      redirect_to project_wiki_path(@project, CGI.escape(@name))
    else
      redirect_to forbidden_path
    end
  end

  def new
    if can? :update, @project
      @name = ''
    else
      redirect_to forbidden_path
    end
  end

  def create
    if can? :update, @project
      @name = params['page']
      format = params['format'].intern

      begin
        @wiki.write_page(@name, format, params['content'], commit)
        redirect_to project_wiki_path(@project, CGI.escape(@name))
      rescue Gollum::DuplicatePageError => e
        flash[:error] = t("flash.wiki.duplicate_page", :name => @name)
        render :action => :new
      end
    else
      redirect_to forbidden_path
    end
  end

  def destroy
    if can? :update, @project
      page = @wiki.page(params[:id])
      if page
        @wiki.delete_page(page, commit.merge(:message => 'Page removed'))
        flash[:notice] = t("flash.wiki.page_successfully_removed")
      else
        flash[:notice] = t("flash.wiki.page_not_found", :name => params[:id])
      end
      redirect_to project_wiki_index_path(@project)
    else
      redirect_to forbidden_path
    end
  end

  def git
    redirect_to forbidden_path if cannot? :read, @project
  end

  def compare
    if can? :read, @project
      @name = params[:id]
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
        page = @wiki.page(@name)
        @diffs = [@wiki.repo.diff(@versions.first, @versions.last, page.path).first]
        render :compare
      else
        redirect_to project_wiki_path(@project, CGI.escape(@name))
      end
    else
      redirect_to forbidden_path
    end
  end

  def compare_wiki
    if can? :read, @project
      if request.post?
        @versions = params[:versions] || []
        if @versions.size < 2
          redirect_to history_project_wiki_index_path(@project)
        else
          redirect_to compare_versions_project_wiki_index_path(@project,
                                                         sprintf('%s...%s', @versions.last, @versions.first))
        end
      elsif request.get?
        @versions = params[:versions].split(/\.{2,3}/)
        if @versions.size < 2
          redirect_to history_project_wiki_index_path(@project)
          return
        end
        @diffs = @wiki.repo.diff(@versions.first, @versions.last)
        render :compare
      else
        redirect_to project_wiki_path(@project, CGI.escape(@name))
      end
    else
      redirect_to forbidden_path
    end
  end

  def revert
    if can? :update, @project
      @name = params[:id]
      @page = @wiki.page(@name)
      sha1  = params[:sha1]
      sha2  = params[:sha2]

      if @wiki.revert_page(@page, sha1, sha2, commit)
        flash[:notice] = t("flash.wiki.revert_success")
        puts 'TEST!!!'
        puts @name
        redirect_to project_wiki_path(@project, CGI.escape(@name))
      else
        # if revert wasn't successful then redirect back to comparsion.
        # if second commit version is missed, then second version is 
        # params[:sha1] and first version is previous version related to params[:sha1]
        sha2, sha1 = sha1, "#{sha1}^" if !sha2
        @versions = [sha1, sha2]
        diffs     = @wiki.repo.diff(@versions.first, @versions.last, @page.path)
        @diffs    = [diffs.first]
        flash[:error]  = t("flash.wiki.patch_does_not_apply")
        render :compare
      end
    else
      redirect_to forbidden_path
    end
  end

  def preview
    if can? :update, @project
      @name = params['page']
      @page = @wiki.preview_page(@name, params['content'], params['format'])
      @content = @page.formatted_data
      @editable = false
      render :show
    else
      redirect_to forbidden_path
    end
  end

  def history
    if can? :read, @project
      @name = params[:id]
      if @page = @wiki.page(@name)
        @versions = @page.versions
      else
        redirect_to :back
      end
    else
      redirect_to forbidden_path
    end
  end

  def wiki_history
    if can? :read, @project
      @versions = @wiki.log
      render :history
    else
      redirect_to forbidden_path
    end
  end

  def search
    if can? :read, @project
      @query = params[:q]
      @results = @wiki.search @query
    else
      redirect_to forbidden_path
    end
  end

  def pages
    if can? :read, @project
      @results = @wiki.pages
      @ref = @wiki.ref
    else
      redirect_to forbidden_path
    end
  end

  protected

    def get_wiki
      @wiki = Gollum::Wiki.new(@project.wiki_path,
               WIKI_OPTIONS.merge(:base_path => project_wiki_index_path(@project)))
    end

    # This method was grabbed from sinatra application, shipped with Gollum gem.
    # See Gollum gem and Gollum License if you have any questions about license notes.
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
#        msg = "#{!!@wiki.page(@name) ? 'Updated page' : 'Created page'} #{@name}"
        msg = case action_name.to_s
          when 'create' then 'Created page '
          when 'update' then 'Updated page '
          when 'revert' then 'Reverted page '
        end + @name.to_s
      end
      { :message => msg }
    end

    def commit
      commit_message.merge({:name => current_user.name, :email => current_user.email})
    end

    def show_or_create_page
      if @page
        @content = @page.formatted_data
        @editable = can?(:update, @project)
        render :show
      elsif file = @wiki.file(@name)
        render :text => file.raw_data, :content_type => file.mime_type
      elsif can? :update, @project
        @new = true
        render :new
      else
        redirect_to forbidden_path
      end
    end
end

