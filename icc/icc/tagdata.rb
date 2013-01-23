class ICC
  class ITagAccessor
    include IOUtils

    def initialize(fh, itt, options = {})
      @fh       = fh
      @tagtable = itt
      @data     = nil
      @options  = options
    end
  end

  class TagDataReader < ITagAccessor
    def initialize(fh, itt, options = {})
      super
      @data           = read_data
      @tagtable       = itt
      @data_start_pos = 128 + 4 + @tagtable.size * 12
    end

    def get(tag)
      signature = tag.to_sym
      offset    = @tagtable[signature].offset - @data_start_pos
      size      = @tagtable[signature].size

      if offset < 0
        raise "offset of tag(#{tag}) invalid: value = #{@tagtable[signature].offset}"
      end
      tag_data = @data[offset, size]
      ICC::TagType::tag_factory(signature, tag_data)
    end
  end

  # TODO:
  class TagDataWriter < ITagAccessor
  end

  # TODO:
  class TagDataUpdater < ITagAccessor
  end
end

