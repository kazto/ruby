#!/usr/bin/ruby

class ICC
  module IOUtils
    def read_data(sz = nil)
      @fh.read(sz)
    end

    def set_pos(v)
      @fh.pos = v
    end
  end

  module NumericType
    NumericFormat = {
      :DateTimeNumber   => "n6",
      :Response16Number => "nx2N",
      :S15Fixed16Number => "N",
      :U16Fixed16Number => "N",
      :U8Fixed8Number   => "n",
      :UInt16Number     => "n",
      :UInt32Number     => "N",
      :UInt64Number     => "N2",
      :UInt8Number      => "C",
      :XYZNumber        => "N3",
    }

    class INumericType
      def initialize(v)
        @val = v
        @type = self.class.name.split("::").last.to_sym
      end

      def encode
        fmt = NumericFormat[@type]
        raise if fmt.nil?
        @val = Array(@val).pack(fmt)
      end

      def decode
        fmt = NumericFormat[@type]
        raise if fmt.nil?
        @val = @val.to_s.unpack(fmt)
      end
    end

    NumericFormat.keys.each do |clsname|
      const_set(clsname, Class.new(INumericType) )
    end
  end
end
