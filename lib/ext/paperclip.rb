# Patch to use paperclip with nginx upload module
module Paperclip
  class Attachment
    class UploadedPath
      attr_reader :original_filename, :content_type, :size, :path
      def initialize(uploaded_file)
        @original_filename    = uploaded_file["name"].downcase
        @content_type = uploaded_file["content_type"].to_s.strip
        @file_size    = uploaded_file["size"].to_i
        @path         = uploaded_file["path"]
      end

      # TODO remove failed files

      def to_tempfile; self; end

      def size; @file_size; end

      def close; end
      def closed?; true; end
    end

    def assign_with_upload(uploaded_file)
      uploaded_file = UploadedPath.new(uploaded_file) if uploaded_file.is_a?(Hash)
      assign_without_upload(uploaded_file) 
    end
    alias_method_chain :assign, :upload
  end
end
