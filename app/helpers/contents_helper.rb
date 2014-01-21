module ContentsHelper

  def build_content_paths(platform, path)
    paths = ['/']
    paths |= path.split('/').select(&:present?)
    paths.uniq!

    compound_path = ''
    paths.map do |p|
      compound_path << p << '/' if p != '/'
      link_to(platform_content_path(platform, compound_path), {remote: true}) do
        content_tag(:span, p, {class: 'text'}) +
        content_tag(:span, '', {class: 'arrow-right'})
      end
    end.join.html_safe
  end

  def platform_content_path(platform, path, name = nil)
    full_path = platform_contents_path(platform)
    full_path << '/' << path if path.present?
    full_path << ('/' << name) if name.present?
    full_path
  end

end
