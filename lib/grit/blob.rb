# -*- ruby encoding: utf-8 -*-

module Grit
  class Blob

    DEFAULT_RAW_MIME_TYPE = MIME::Types[DEFAULT_MIME_TYPE].first

    delegate :binary?, :ascii?, :encoding, :to => :raw_mime_type

    def mime_type_with_class_store
      set_associated_mimes
      @associated_mimes.first.simplified
    end
    alias_method_chain :mime_type, :class_store

    attr_accessor :raw_mime_type
    def raw_mime_type
      set_associated_mimes
      @raw_mime_type = @associated_mimes.first || DEFAULT_RAW_MIME_TYPE
      @raw_mime_type
    end

    def raw_mime_types
      set_associated_mimes
    end

    protected

      # store all associated MIME::Types inside class
      def set_associated_mimes
        @associated_mimes ||= MIME::Types.type_for(self.name) rescue [DEFAULT_RAW_MIME_TYPE]
        @associated_mimes = [DEFAULT_RAW_MIME_TYPE] if @associated_mimes.empty?
        @associated_mimes
      end

  end
end
