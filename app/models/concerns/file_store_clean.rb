module FileStoreClean
  extend ActiveSupport::Concern

  included do
    later :destroy, queue: :middle
    later :later_destroy_files_from_file_store, queue: :middle
  end

  def destroy
    destroy_files_from_file_store if Rails.env.production?
    super
  end

  def sha1_of_file_store_files
    raise NotImplementedError, "You should implement this method"
  end

  def destroy_files_from_file_store(args = sha1_of_file_store_files)
    files = *args
    files.each do |sha1|
      FileStoreService::File.new(sha1: sha1).destroy
    end
  end

  def later_destroy_files_from_file_store(args)
    destroy_files_from_file_store(args)
  end

end
