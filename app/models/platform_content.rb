class PlatformContent

  attr_reader :path

  def initialize(platform, path)
    @platform, @path = platform, path
  end

  def build_list
    return @build_list if !!@build_list
    return nil if @path !~ /\/(release|updates)+\/[\w\-\.]+$/
    return nil unless repository_name = @path.match(/\/[\w]+\/(release|updates)\//)
    repository_name = repository_name[0].gsub(/\/(release|updates)\/$/, '').gsub('/', '')

    repository = @platform.repositories.where(name: repository_name).first
    return nil unless repository

    if @platform.main?
      build_for_platform = @platform
    else
      bfp_name = @path.match(/\/#{@platform.name}\/repository\/[\w]+\//)
      return nil unless bfp_name
      bfp_name = bfp_name[0].gsub(/\/#{@platform.name}\/repository\//, '').gsub('/', '')
      build_for_platform = Platform.main.find_by_name bfp_name
      return nil unless build_for_platform
    end

    @build_list  = BuildList.for_status(BuildList::BUILD_PUBLISHED)
                            .for_platform(build_for_platform)
                            .scoped_to_save_platform(@platform)
                            .where(save_to_repository_id: repository)
                            .where(build_list_packages: {fullname: name, actual: true})
                            .joins(:packages)
                            .last

    return @build_list
  end

  def name
    @name ||= @path.gsub(/.*#{File::SEPARATOR}/, '')
  end

  def size
    @size ||= File.size(@path) rescue nil
  end

  def is_folder?
    @is_folder.nil? ? (@is_folder = File.directory?(@path)) : @is_folder
  end

  def download_url
    suffix = @path.gsub(/^#{@platform.path}/, '')
    "#{APP_CONFIG['downloads_url']}/#{@platform.name}#{suffix}"
  end

  def self.find_by_platform(platform, path, term)
    # Strip out the non-ascii character
    term = (term || '').strip.gsub(/[\\\/]+/, '')
                             .gsub(/[^\w\-\+\.]/, '_')

    path = path.split(File::SEPARATOR).map(&:strip).select(&:present?)
               .map{ |p|
                  # Strip out the non-ascii character
                  p.gsub(/[\\\/]+/, '')
                   .gsub(/^[\.]+/, '')
                   .gsub(/[^\w\-\.]/, '_')
                }
               .join(File::SEPARATOR)
    results = Dir.glob(File.join(platform.path, path, "*#{term}*"))
    if term
      results = results.sort_by(&:length)
    else
      results = results.sort
    end
    results.map{ |p| PlatformContent.new(platform, p) }
  end

end