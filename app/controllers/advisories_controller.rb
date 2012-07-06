# -*- encoding : utf-8 -*-
class AdvisoriesController < ApplicationController
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user! if APP_CONFIG['anonymous_access']
  load_resource :find_by => :advisory_id
  authorize_resource

  before_filter :fetch_packages_info, :only => [:show]

  def index
    @advisories = @advisories.scoped(:include => :platforms)
    @advisories = @advisories.search_by_id(params[:q]) if params[:q]
    @advisories = @advisories.paginate(:page => params[:page])
    respond_to do |format|
      format.html
      format.atom
    end
  end

  def show
  end

  def search
    @advisory = Advisory.by_update_type(params[:bl_type]).search_by_id(params[:query]).first
    raise ActionController::RoutingError.new('Not Found') if @advisory.nil?
    respond_to do |format|
      format.json { render @advisory }
    end
  end

  protected

  # this method fetches and structurize packages attached to current advisory.
  def fetch_packages_info
    @packages_info = Hash.new { |h, k| h[k] = {} } # maaagic, it's maaagic ;)
    @advisory.build_lists.find_in_batches(:include => [:save_to_platform, :packages, :project]) do |batch|
      batch.each do |build_list|
        tmp = build_list.packages.inject({:srpm => nil, :rpm => []}) do |h, p|
          p.package_type == 'binary' ? h[:rpm] << p.fullname : h[:srpm] = p.fullname
          h
        end
        h = { build_list.project => tmp }
        @packages_info[build_list.save_to_platform].merge!(h) do |pr, old, new|
          {:srpm => new[:srpm], :rpm => old[:rpm].concat(new[:rpm]).uniq}
        end
      end
    end
  end

end
