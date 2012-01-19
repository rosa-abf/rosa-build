require 'lib/gollum'
require 'cgi'

class WikiController < ApplicationController
#  WIKI_OPTIONS = {:page_file_dir => '/', :ref => 'master', :page_class => Gollum::PageImproved}
#  WIKI_OPTIONS = { :page_class => Gollum::PageImproved}
  WIKI_OPTIONS = {}

  load_and_authorize_resource :project

  before_filter :get_wiki

  def index
    @name = 'Home'
    if page = @wiki.page(@name)
      @page = page
      @content = page.formatted_data
      @editable = true
      render :show
    elsif file = @wiki.file(@name)
      render :text => file.raw_data, :content_type => file.mime_type
    else
      @new = true
      @content = ''
      render :new
    end
  end

  def show
    @name = params['id']
    ref = params['ref'] ? params['ref'] : @wiki.ref
    @page = @wiki.page(@name, ref)
    if !@page && @wiki.page(@name)
      flash[:error] = t('flash.wiki.ref_not_exist')
      redirect_to project_wiki_path(@project, CGI.escape(@name))
      return
    end

    if @page
      @content = @page.formatted_data
      @editable = true
      render
    else
      @new = true
      render :new
    end
  end

  def edit
    @name = params[:id]
    if page = @wiki.page(@name)
      @page = page
      @content = page.raw_data
      render :edit
    else
      render :new
    end
  end

  def update
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
  end

  def new
    @name = ''
  end

  def create
    @name = params['page']
    format = params['format'].intern

    begin
      @wiki.write_page(@name, format, params['content'], commit)
      redirect_to project_wiki_path(@project, CGI.escape(@name))
    rescue Gollum::DuplicatePageError => e
      flash[:error] = t("flash.wiki.duplicate_page", :name => @name)
      render :action => :new
    end
  end

  def destroy
    page = @wiki.page(params[:id])
    if page
      @wiki.delete_page(page, commit.merge(:message => 'Page removed'))
      flash[:notice] = t("flash.wiki.page_successfully_removed")
    else
      flash[:notice] = t("flash.wiki.page_not_found", :name => params[:id])
    end
    redirect_to project_wiki_index_path(@project)
  end

  def compare
    @name = params[:id]
    if request.post?
      @versions = params[:versions] || []
      if @versions.size < 2
        if @name
          redirect_to history_project_wiki_path(@project, CGI.escape(@name))
        else
          redirect_to history_project_wiki_index_path(@project)
        end
      else
        if @name
          redirect_to compare_versions_project_wiki_path(@project, CGI.escape(@name),
                                                       sprintf('%s...%s', @versions.last, @versions.first))
        else
          redirect_to compare_versions_project_wiki_index_path(@project,
                                                       sprintf('%s...%s', @versions.last, @versions.first))
        end
      end
    elsif request.get?
      @versions = params[:versions].split(/\.{2,3}/)
      if @versions.size < 2
        if @name
          redirect_to history_project_wiki_path(@project, CGI.escape(@name))
        else
          redirect_to history_project_wiki_index_path(@project)
          return
        end
      end
      if @name
        page = @wiki.page(@name)
        @diff = @wiki.repo.diff(@versions.first, @versions.last, page.path).first
        @diffs = [@diff]
      else
        @diffs = @wiki.repo.diff(@versions.first, @versions.last)
      end
      render :compare
    else
      redirect_to project_wiki_path(@project, CGI.escape(@name))
    end
  end

  def revert
    @name = params[:id]
    @page = @wiki.page(@name)
    sha1  = params[:sha1]
    sha2  = params[:sha2]

    if @wiki.revert_page(@page, sha1, sha2, commit_message)
      flash[:notice]  = t("flash.wiki.revert_success")
      redirect_to project_wiki_path(@project, "#{CGI.escape(@name)}")
    else
      sha2, sha1 = sha1, "#{sha1}^" if !sha2
      @versions = [sha1, sha2]
      diffs     = @wiki.repo.diff(@versions.first, @versions.last, @page.path)
      @diff     = diffs.first
      @helper = WikiHelper::CompareHelper.new(@diff, @versions)
      flash[:error]  = t("flash.wiki.patch_does_not_apply")
      render :compare
    end
  end

  def preview
    puts @wiki.inspect
    puts params['content']
    puts params['format']
    @name = params['page']#'Preview'
    @page = @wiki.preview_page(@name, params['content'], params['format'])
    puts @page.inspect
    puts @page.version.inspect
    @content = @page.formatted_data
    @editable = false
    render :show
  end

  def history
    if @name = params['id']
      if @page = @wiki.page(@name)
        @versions = @page.versions(:per_page => 1000000)#(:page => params['page'], :per_page => 25)#.paginate :page => params[:page] #try to use will_paginate
      else
        redirect_to :back
      end
    else
      @versions = @wiki.log(:per_page => 100000)
    end
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
      @wiki = Gollum::Wiki.new(@project.wiki_path, WIKI_OPTIONS.merge(:base_path => project_wiki_index_path(@project)))
    end

    def update_wiki_page(wiki, page, content, commit_message, name = nil, format = nil)
      return if !page ||  
        ((!content || page.raw_data == content) && page.format == format)
      name    ||= page.name
      format    = (format || page.format).to_sym
      content ||= page.raw_data
      wiki.update_page(page, name, format, content.to_s, commit_message)
    end

    def commit_message
      { :message => params['message'] }
    end

    def commit
      commit_message.merge({:name => current_user.name, :email => current_user.email})
    end
end

