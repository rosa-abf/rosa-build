require 'ffi'

module RPM
  def self.compareVREs(vre1, vre2)
    e1, v1, r1 = vre1
    e2, v2, r2 = vre2

    e1 = '0' if !e1.present?
    e2 = '0' if !e2.present?

    rc = compare_values(e1, e2)
    if rc == 0
      rc = compare_values(v1, v2)
      if rc == 0
        rc = compare_values(r1, r2)
      end
    end

    return rc
  end

  class << self
    private

    def compare_values(val1, val2)
      if !val1.present? && !val2.present?
        return 0
      elsif val1.present? && !val2.present?
        return 1
      elsif !val1.present? && val2.present?
        return -1
      end

      return C.rpmvercmp(val1, val2)
    end
  end

  module C

    extend ::FFI::Library

    begin
      ffi_lib ['librpm.so.9', 'rpm']
    rescue LoadError => e
      raise(
        "Can't find rpm libs on your system: #{e.message}"
      )
    end

    attach_function 'rpmvercmp', [:string, :string], :int

  end
end
