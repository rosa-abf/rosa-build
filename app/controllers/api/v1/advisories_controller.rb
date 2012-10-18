# -*- encoding : utf-8 -*-
class Api::V1::AdvisoriesController < Api::V1::BaseController
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user! if APP_CONFIG['anonymous_access']
  load_resource :find_by => :advisory_id
  authorize_resource

  def index
    @advisories = @advisories.scoped(:include => :platforms).
      paginate(paginate_params)
  end

  def show
    fetch_packages_info
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
