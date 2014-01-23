class MaintainerPresenter < ApplicationPresenter

  attr_reader :package, :package_link, :package_name, :package_type,
              :package_version, :package_release, :package_version_release,
              :package_updated_at
  attr_reader :maintainer, :maintainer_fullname, :maintainer_email,
              :maintainer_link, :maintainer_mail_link
  delegate :package_type, to: :package

  [:name, :version, :release, :updated_at].each do |meth|
    define_method "package_#{meth}" do
      @package.send meth
    end
  end

  [:fullname, :email].each do |meth|
    define_method "maintainer_#{meth}" do
      @maintainer.send meth
    end
  end

  def initialize(package, opts = {})
    @package = package
    @maintainer = package.try(:assignee)
  end

  def package_link
    link_to @package.name, @package.project
  end

  def package_version_release
    "#{@package.version}-#{@package.release}"
  end

  def maintainer_link
    link_to @maintainer.fullname, @maintainer
  end

  def maintainer_email_link
    mail_to @maintainer.email, @maintainer.email, encode: "javascript"
  end

end
