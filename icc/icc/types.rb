=begin
=How to create private tag type.
 1. add_tagdata_subclass(Array of Symbols) to ICC class.

class ICC
  add_tagdata_subclass([:ADD1, :ADD2, ... ])
end

 2. define class

class ICC::ADD1
  def parse
    super { "(parse format string by ExPack format)" }
  end

  def accessor1
    # define accessor method for Array @data
  end
end

 3. use ICC class

icc = ICC.new
icc.load("profile_with_priv_tag.icc")

=end

class ICC
  module TagType
    #
    # ICC Tag Definition
    #
    @@TagTypeNameTable_v2 = [
      # v2
      :CHRM, :CRDI, :CURV, :DATA, :DTIM, :DEVS, :MFT2,
      :MFT1, :MEAS, :NCOL, :NCL2, :PSEQ, :RCS2, :SF32,
      :SCRN, :SIG_, :DESC, :TEXT, :UF32, :BFD_, :UI16,
      :UI32, :UI64, :UI08, :VIEW, :XYZ_,
    ]
    @@TagTypeNameTable_v4 = [
      # v4
      :CLRO, :CLRT, :MAB_, :MBA_, :MLUC, :PARA,
    ]

    @@TagTypeNameTable = [:DefaultTag]
    @@TagTypeTable = {}
    class ITagData
      def initialize(sig, data)
        @signature = sig.to_s
        @tagtype = data[0, 4]
        @bindata = data
        @data = []
        @xp = ExPack.new
        @xp.load(@bindata)
        parse
      end

      def parse(&block)
        if block_given?
          @xp.unpackex(&block)
        else
          raise ArgumentError.new
        end
        @data.concat(@xp.data)
        @data
      end

      def keys
        (self.class.instance_methods - self.class.superclass.instance_methods).sort
      end

      attr_accessor :signature, :tagtype, :data
    end

    def self.add_tagdata_subclass(clss)
      clss.each do |clsname|
        @@TagTypeTable[clsname] = Class.new(ITagData)
        const_set(clsname, @@TagTypeTable[clsname])
      end
      @@TagTypeNameTable.concat(clss)
    end

    add_tagdata_subclass(@@TagTypeNameTable_v2)
    add_tagdata_subclass(@@TagTypeNameTable_v4)

    def self.tag_factory(tag_signature, tag_data)
      tag_type = tag_data[0,4].upcase.gsub(/ /,'_').to_sym
      unless @@TagTypeNameTable.include?(tag_type)
        tag_type = :DefaultTag
      end
      @@TagTypeTable[tag_type].new(tag_signature, tag_data)
    end
  end
end

class ICC::TagType::DefaultTag
  def parse
    super { "a4x4a*" }
  end
end

class ICC::TagType::XYZ_
  def parse
    super { "a4x4NNN" }
  end

  def x ; @data[1] ; end
  def y ; @data[2] ; end
  def z ; @data[3] ; end
end

