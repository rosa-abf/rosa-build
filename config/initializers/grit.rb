# -*- encoding : utf-8 -*-

require './lib/grit1'

GAP_REPO_PATH = '/tmp/gap_repo.git'
unless File.directory? GAP_REPO_PATH
  Grit::Repo.init_bare(GAP_REPO_PATH)
  # FileUtils.chmod "a-w", GAP_REPO_PATH
end
