class Gollum::BlobEntry
  def name
    @name ||= begin
      fname = ::File.basename(@path)
      fname = fname.gsub(/\\\d+/).each { |q| q[1..-1].to_i(8).chr }.force_encoding('utf-8')
      fname.gsub!(/^"/, '')
      fname.gsub!(/"$/, '')
      fname
    end
  end
end
