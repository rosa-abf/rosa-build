module KeyPairsHelper

  def key_pair_repository_options(platform)
    platform.repositories.map do |r|
      [r.name, r.id]
    end
  end
end