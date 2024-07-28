class IntegrityCheckJob
  @queue = :low

  def self.perform
    integrity_path = Rails.root.join('public', 'integrity')
    Dir.mkdir(integrity_path, 0755) rescue nil

    start_time = Time.now.utc
    result = ['rosa2019.05', 'rosa2021.1', 'rosa2021.15', 'rosa2023.1'].map do |name|
      platform = Platform.find_by(name: name)
      next unless platform

      [name, PlatformService::PlatformIntegrityChecker.new(platform).call]
    end
    end_time = Time.now.utc
    duration = end_time - start_time
    start_time_str = start_time.strftime('%Y-%m-%d %H:%M:%S UTC')
    generated_str = "Generated on #{start_time_str} in #{duration} seconds."

    index = Slim::Template.new(Rails.root.join('app','views','integrity','index.html.slim').to_s).render(
      generated_str: generated_str,
      result: result
    )
    File.write(integrity_path.join("index.html"), index)
    result.each do |r|
      platform, p_res = r
      p_res[:repositories].each do |repository|
        fname = "#{platform}_#{repository}.html"
        repo_page = Slim::Template.new(Rails.root.join('app','views','integrity','repository.html.slim').to_s).render(
          generated_str: generated_str,
          result: p_res,
          repository: repository
        )
        File.write(integrity_path.join(fname), repo_page)
      end
    end

    nil
  end
end