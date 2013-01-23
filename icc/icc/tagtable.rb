class ICC
  #
  # Tag Table classes
  #
  class ITagTable
    include IOUtils

    class Element
      def initialize(itt, ary = [])
        raise ArgumentError.new("ITagTable::Element constructor requires ITagTable obj.") unless itt.is_a? ITagTable
        raise ArgumentError.new("ITagTable::Element constructor requires Array obj.") unless ary.is_a? Array
        @tagtable = itt
        @data     = ary[0..2]
      end

      def signature ; @data[0] ; end
      def offset    ; @data[1] ; end
      def size      ; @data[2] ; end
      def to_a      ; @data    ; end

      # debug
      def inspect
        to_a.inspect
      end

      def get
        @tagtable.get(self)
      end
    end

    def initialize(fh)
      raise ArgumentError.new("ITagTable constructor requires IO obj.") unless fh.is_a? IO
      @fh = fh
      @tagCount = 0
      @tags = Array.new
      @data = Array.new
    end

    def parse
      raw_data = read_data(4)
      @tagCount = raw_data.unpack("N").first

      raw_data << read_data(4*3*@tagCount)
      tmp_data = raw_data.unpack("x4" + "a4N2" * @tagCount)
      tmp_data.map! { |it| if it.is_a? String ; it.to_sym ; else it ; end }

      @tagCount.times do |n|
        @data << Element.new(self, tmp_data.shift(3))
      end
    end

    def binsize
      4 + @tagCount.to_i * 12
    end
  end

  class TagTableReader < ITagTable
    def initialize(fh)
      super
      parse
    end

    def table
      @data.to_a
    end

    def data
      
    end

    def size
      @data.size
    end

    def signatures
      @data.collect { |elem| elem.signature }
    end

    def [](key)
      @data.find { |elem| elem.signature == key }
    end
  end

  # TODO:
  class TagTableWriter < ITagTable
  end

  # TODO:
  class TagTableUpdater < ITagTable
  end
end

