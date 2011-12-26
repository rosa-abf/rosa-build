require 'cgi'

class WikiController < ApplicationController
  WIKI_OPTIONS = {:page_file_dir => '/', :ref => 'master'}

  load_and_authorize_resource :project

  before_filter :get_wiki

  def index
    @name = 'Home'
    if page = @wiki.page(@name)
      @page = page
      @content = page.formatted_data
      @editable = true
      render :show
    else
      render :new
    end
  end

  def show
    @name = params[:id]
    rev = params[:rev] ? params[:rev] : nil

  end

  def edit
  end

  def update
  end

  def new
  end

  def create
    @name = params[:name]
    format = params[:format].intern

    begin
      @wiki.write_page(@name, format, params[:content], commit_message)
      redirect project_wiki_path(@project, @name)
    rescue Gollum::DuplicatePageError => e
      @message = "Duplicate page: #{@name}"
      render :action => :new
    end
  end

  def destroy
  end

  def compare
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
      @page = @wiki.page(@name)
      diffs = @wiki.repo.diff(@versions.first, @versions.last, @page.path)
      @diff = diffs.first
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
      redirect_to project_wiki_path(@project, "#{CGI.escape(@name)}")
    else
      sha2, sha1 = sha1, "#{sha1}^" if !sha2
      @versions = [sha1, sha2]
      diffs     = @wiki.repo.diff(@versions.first, @versions.last, @page.path)
      @diff     = diffs.first
      @message  = "The patch does not apply."
      render :compare
    end
  end

  def preview
    @name = 'Preview'
    @page = @wiki.preview_page(@name, params[:content], params[:format])
    @content = @page.formatted_data
    @editable = false
    render :show
  end

  def history
    @name = params[:name]
    @page = @wiki.page(@name)
    @versions = @page.versions :page => params[:page] #try to use will_paginate
  end

  def search
    @query = params[:q]
    @results = @wiki.search @query
    @name = @query
  end

  def pages
    @results = @wiki.pages
    @ref = @wiki.ref
  end

  protected

    def get_wiki
      @wiki = Gollum::Wiki.new(@project.wiki_path, WIKI_OPTIONS.merge(:base_path => project_wiki_path(@project)))
    end

    def commit_message
      { :message => params[:message] }
    end
end

