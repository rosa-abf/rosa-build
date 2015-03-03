# Internal: various definitions and instance methods related to AbfWorker.
#
# This module gets mixed in into ProductBuildList class.
module ProductBuildList::AbfWorkerable
  extend ActiveSupport::Concern

  CACHED_CHROOT_TOKEN_DESCRIPTION = 'cached-chroot'

  include AbfWorkerMethods

  included do
    delegate :url_helpers, to: 'Rails.application.routes'

    after_create :add_job_to_abf_worker_queue
  end


  ######################################
  #          Instance methods          #
  ######################################

  def sha1_of_file_store_files
    (results || []).map{ |r| r['sha1'] }.compact
  end

  protected

  def abf_worker_priority
    ''
  end

  def abf_worker_base_queue
    'iso_worker'
  end

  def abf_worker_args
    file_name = "#{project.name}-#{commit_hash}"
    opts      = default_url_options
    opts.merge!({user: user.authentication_token, password: ''}) if user.present?
    srcpath = url_helpers.archive_url(
      project.name_with_owner,
      file_name,
      'tar.gz',
      opts
    )

    cmd_params = "BUILD_ID=#{id} "
    if product.platform.hidden?
      token = product.platform.tokens.by_active.where(description: CACHED_CHROOT_TOKEN_DESCRIPTION).first
      cmd_params << "TOKEN=#{token.authentication_token} " if token
    end
    cmd_params << params.to_s

    {
      id: id,
      srcpath:      srcpath,
      params:       cmd_params,
      time_living:  time_living,
      main_script:  main_script,
      platform: {
        type: product.platform.distrib_type,
        name: product.platform.name,
        arch: arch.name
      },
      user: {uname: user.try(:uname), email: user.try(:email)}
    }
  end

end
