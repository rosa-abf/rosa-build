class WikiPage < Struct.new(:page, :format, :content, :footer, :sidebar)
  include ActiveModel::Conversion
  extend  ActiveModel::Naming

  attr_accessor :message, :rename

  def rename
    @rename ||= page
  end

end