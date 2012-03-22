# -*- encoding : utf-8 -*-
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
        @associated_mimes ||= []
        if @associated_mimes.empty?
          guesses = MIME::Types.type_for(self.name) rescue [DEFAULT_RAW_MIME_TYPE]
          guesses = [DEFAULT_RAW_MIME_TYPE] if guesses.empty?

          @associated_mimes = guesses.sort{|a,b| mime_sort(a, b)}
        end
        @associated_mimes
      end

      # TODO make more clever function
      def mime_sort(a,b)
        return 0 if a.media_type == b.media_type and a.registered? == b.registered?
        return -1 if a.media_type == 'text' and !a.registered?
        return 1
      end

  end
end
