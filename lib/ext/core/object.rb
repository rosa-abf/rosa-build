class Object
  alias_method :base_to_s, :to_s

  def to_s
    res = base_to_s.dup
    res.force_encoding(Encoding.default_internal || Encoding::UTF_8)
  end
end
