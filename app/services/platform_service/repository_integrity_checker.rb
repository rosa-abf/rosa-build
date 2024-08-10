# frozen_string_literal: true

class PlatformService::RepositoryIntegrityChecker
  attr_reader :repository, :platform, :arches

  def initialize(repository, arches)
    @repository = repository
    @arches = arches
    @platform = repository.platform
  end

  def call
    result = {}
    Arch.where(id: arches).find_each do |arch|
      result.merge!(process_arch(arch))
    end

    result.merge!(process_srpms)

    result
  end

  private

  def process_arch(arch)
    _, separated_for_extra = actual_packages(
      package_type: 'binary',
      arch_id: arch.id
    )
    bls_for_missing, separated_for_missing = actual_packages(
      package_type: 'binary',
      arch_id: arch.id,
      for_version: platform.default_branch
    )

    result = {}

    ['', 'debug_'].each do |prefix|
      repo_name = "#{prefix}#{repository.name}"
      path = Pathname.new(platform.path).join('repository', arch.name, repo_name)
      present_packages = rpms_from_fs(path)
      arch_result = if prefix.empty?
                      {
                        missing_packages: separated_for_missing[:repo_packages] - present_packages,
                        extra_packages: present_packages - separated_for_extra[:repo_packages]
                      }
                    else
                      {
                        missing_packages: separated_for_missing[:debug_packages] - present_packages,
                        extra_packages: present_packages - separated_for_extra[:debug_packages]
                      }
                    end
      arch_result[:missing_from_build_lists] = BuildList::Package.where(
        build_list_id: bls_for_missing,
        actual: true,
        package_type: 'binary',
        fullname: arch_result[:missing_packages]
      ).reorder('').distinct.pluck(:build_list_id)

      arch_result[:missing_from_projects] = BuildList.joins(:project).where(
        'build_lists.id' => arch_result[:missing_from_build_lists]
      ).pluck('projects.owner_uname', 'projects.name').map { |x| x.join('/') }

      result["#{arch.name}##{repo_name}"] = arch_result
    end

    result
  end

  def process_srpms
    _, actual_for_extra = actual_packages(
      package_type: 'source',
      separate: false,
    )
    bls_for_missing, actual_for_missing = actual_packages(
      package_type: 'source',
      separate: false,
      for_version: platform.default_branch
    )

    path = Pathname.new(platform.path).join('repository', 'SRPMS', repository.name)
    present_packages = rpms_from_fs(path)
    res = {
      missing_packages: actual_for_missing - present_packages,
      extra_packages: present_packages - actual_for_extra
    }

    res[:missing_from_build_lists] = BuildList::Package.where(
      build_list_id: bls_for_missing,
      actual: true,
      package_type: 'source',
      fullname: res[:missing_packages]
    ).reorder('').distinct.pluck(:build_list_id)

    res[:missing_from_projects] = BuildList.joins(:project).where(
      'build_lists.id' => res[:missing_from_build_lists]
    ).pluck('projects.owner_uname', 'projects.name').map { |x| x.join('/') }

    return { "SRPMS##{repository.name}" => res }
  end

  def rpms_from_fs(path)
    result = []
    %w[release updates].each do |type|
      result |= Dir.glob(path.join(type, '*.rpm')).map { |x| x.split('/').last }
    end

    result
  end

  def actual_packages(package_type:, separate: true, arch_id: nil, for_version: nil)
    bls = BuildList.where(
      save_to_repository_id: repository.id,
      project_id: repository.projects
    )

    if for_version
      bls = bls.where(project_version: for_version)
    end
    if arch_id
      bls = bls.where(arch_id: arch_id)
    end

    actual_packages = BuildList::Package.where(
      build_list_id: bls,
      actual: true,
      package_type: package_type
    ).reorder('').distinct.pluck(:fullname)

    if separate
      [bls, separate_debug_packages(actual_packages)]
    else
      [bls, actual_packages]
    end
  end

  def separate_debug_packages(list)
    res = {
      repo_packages: [],
      debug_packages: []
    }

    list.each do |package|
      if package['-debuginfo-'] || package['-debugsource-']
        res[:debug_packages] << package
      else
        res[:repo_packages] << package
      end
    end

    res
  end
end
