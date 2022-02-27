# Internal: various definitions and instance methods related to AbfWorker.
#
# This module gets mixed in into ProductBuildList class.
module ProductBuildLists::AbfWorkerable
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
    {
      id:           id,
      srcpath:      abf_worker_srcpath,
      params:       abf_worker_params,
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

  # Private: Get URL to project archive.
  #
  # Returns the String.
  def abf_worker_srcpath
    file_name = "#{project.name}-#{commit_hash}"
    opts      = default_url_options
    opts.merge!({user: user.authentication_token, password: ''}) if user.present?
    url_helpers.archive_url(
      project.name_with_owner,
      file_name,
      'tar.gz',
      opts
    )
  end

  # Private: Get params for ABF worker task.
  #
  # Returns the String with space separated params.
  def abf_worker_params
    p = {
      'BUILD_ID'        => id,
      'PROJECT'         => project.name_with_owner,
      'PROJECT_VERSION' => project_version,
      'COMMIT_HASH'     => commit_hash,
      'API_TOKEN'       => User.find('iso_builder_system').authentication_token
    }
    if product.platform.hidden?
      token = product.platform.tokens.by_active.where(description: CACHED_CHROOT_TOKEN_DESCRIPTION).first
      p.merge!('TOKEN' => token.authentication_token) if token
    end
    p.map{ |k, v| "#{k}=#{v}" } * ' ' + ' ' + params.to_s
  end

end
