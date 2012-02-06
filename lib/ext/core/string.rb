class String
  def encode_to_default
    force_encoding(Encoding.default_internal || Encoding::UTF_8)
  end
end
