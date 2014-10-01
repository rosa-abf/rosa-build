class CreateEmptyMetadataJob < Struct.new(:class_name, :id)
  @queue = :low

  def perform
    case class_name
    when Platform.name
      create_empty_metadata_for_platform
    when Repository.name
      create_empty_metadata_for_repository Repository.find(id)
    end
  end

  def self.perform(class_name, id)
    new(class_name, id).perform
  end

  private

  def create_empty_metadata_for_platform
    platform      = Platform.main.find id
    @platforms    = [platform]
    repositories  = Repository.joins(:platform).
      where(platforms: { platform_type: Platform::TYPE_PERSONAL })
    repositories.find_each do |r|
      create_empty_metadata_for_repository r
    end
  end

  def create_empty_metadata_for_repository(repository)
    @platforms = [repository.platform] if repository.platform.main?
    platforms.each do |platform|
      arch_names.each do |arch_name|
        %w(release updates).each do |type|
          path  = "#{ repository.platform.path }/repository/"
          path << "#{ platform.name }/" if repository.platform.personal?
          path << "#{ arch_name }/#{ repository.name }/#{ type }"
          create_empty_metadata(platform, path)
        end
      end
    end
  end

  def create_empty_metadata(platform, path)
    case platform.distrib_type
    when 'rhel'
      path << '/repodata/'
    when 'mdv'
      path << '/media_info/'
    else
      return
    end
    if Dir["#{ path }/*"].empty?
      system "mkdir -p -m 0777 #{ path }"
      system "cp -f #{ empty_metadatas(platform) }/* #{ path }/"
    end
  end

  def empty_metadatas(platform)
    Rails.root.join('public', 'metadatas', platform.distrib_type).to_s
  end

  def arch_names
    @arch_names ||= Arch.pluck(:name)
  end

  def platforms
    @platforms ||= Platform.main.to_a
  end

end
