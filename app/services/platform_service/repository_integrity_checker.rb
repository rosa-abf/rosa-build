# frozen_string_literal: true

class PlatformService::RepositoryIntegrityChecker
  attr_reader :repository, :arches

  def initialize(repository, arches)
    @repository = repository
    @arches = arches
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
    bls = BuildList.where(
      save_to_repository_id: repository.id,
      arch_id: arch.id,
      project_id: repository.projects
    )
    actual_packages = BuildList::Package.where(
      build_list_id: bls,
      actual: true,
      package_type: 'binary'
    ).reorder('').pluck(:fullname)
    separated = separate_debug_packages(actual_packages)

    result = {}

    ['', 'debug_'].each do |prefix|
      repo_name = "#{prefix}#{repository.name}"
      path = Pathname.new(repository.platform.path).join('repository', arch.name, repo_name)
      present_packages = rpms_from_fs(path)
      arch_result = if prefix.empty?
                      {
                        missing_packages: separated[:repo_packages] - present_packages,
                        extra_packages: present_packages - separated[:repo_packages]
                      }
                    else
                      {
                        missing_packages: separated[:debug_packages] - present_packages,
                        extra_packages: present_packages - separated[:debug_packages]
                      }
                    end
      arch_result[:missing_from_build_lists] = BuildList::Package.where(
        build_list_id: bls,
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
    bls = BuildList.where(save_to_repository_id: repository.id, project_id: repository.projects)
    actual_packages = BuildList::Package.where(
      build_list_id: bls,
      actual: true,
      package_type: 'source'
    ).reorder('').distinct.pluck(:fullname)

    path = Pathname.new(repository.platform.path).join('repository', 'SRPMS', repository.name)
    present_packages = rpms_from_fs(path)
    res = {
      missing_packages: actual_packages - present_packages,
      extra_packages: present_packages - actual_packages
    }

    res[:missing_from_build_lists] = BuildList::Package.where(
      build_list_id: bls,
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
