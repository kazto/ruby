#!/usr/bin/ruby

class ICC
  #
  # Delegate Class Definition
  # Header classes
  #
  class IHeader
    include IOUtils

    @@header_elem = [
      # name, format, template_data
      [:size,         "N",   0 ],
      [:prefered_cmm, "a4",  "appl"],
      [:icc_version,  "N",   0x40000000 ],
      [:device_class, "a4",  "mntr"],
      [:color_space,  "a4",  "RGB "],
      [:pcs,          "a4",  "XYZ "],
      [:created,      "n6",  [2012,12,25,12,0,0]], #
      [:magic,        "a4",  "acps"],
      [:platform,     "a4",  "MSFT"],
      [:icc_flag,     "N",   0 ],
      [:manufacturer, "a4",  "ricc"],
      [:device_model, "a4",  "    "],
      [:attributes,   "N2",  [0,0]], #
      [:intent,       "N",   0 ],
      [:illuminant,   "N3",  [63190, 65536, 54061]], #
      [:creator,      "a4",  "ricc"],
      [:reserved,     "a44", "\0"*44]
    ]

    def initialize(fh)
      raise ArgumentError.new("IHeader constructor requires IO obj.") unless fh.is_a? IO
      @fh = fh
      @data = Array.new
      @xp = ExPack.new
      @header_size = 128
    end

    def dump
      @data
    end

    def parse
      @xp.load(read_data(@header_size))
      @@header_elem.each do |v|
        @xp.unpackex{v[1]}
      end
      @data = @xp.data
    end

    attr_reader :header_size
  end

  class HeaderReader < IHeader
    def initialize fh
      super fh
      parse
    end

    @@header_elem.each_with_index do |v, n|
      name = v[0]
      define_method(name) { @data[n] }
    end
  end

  class HeaderWriter < IHeader
    def initialize(fh)
      super fh

      hds_members = @@header_elem.map {|v| v[0]}
      hds = Struct.new("HeaderDataStruct", *hds_members)
      @data = hds.new
      _set_template_values
    end

    def set(hData)
      raise unless hData.is_a? Hash

      hData.each do |k,v|
        if(@data.members.include?(k))
          @data[k] = v
        end
      end
    end

    def update_icc_size(sz)
      
    end

    def _set_template_values
      @@header_elem.each do |val|
        @data[val[0]] = val[2]
      end
    end

    def to_bin
      xp = @xp.packex

      @@header_elem.each do |v|
        val = @data[v[0]]
        fmt = v[1]
        xp << [val, fmt]
      end
      xp.value
    end

    private :_set_template_values
  end

  class HeaderUpdater < IHeader
  end
end

