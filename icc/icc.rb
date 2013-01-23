#!/usr/bin/ruby

=begin rdoc
  ICC class
  * class relations
  ICC
    :: IHeader
    |  > HeaderReader  [v]
    |  > HeaderWriter  [ ]
    |  > HeaderUpdater [ ]
    :: ITagTable
    | :: Element         [v]
    |  > TagTableReader  [v]
    |  > TagTableWriter  [ ]
    |  > TagTableUpdater [ ]
    :: ITagAccessor      [v]
    |  > TagDataReader   [v]
    |  > TagDataWriter   [ ]
    |  > TagDataUpdater  [ ]
    :: INumericType
    |  > DateTimeNumber,   Response16Number, S15Fixed16Number,
    |  > U16Fixed16Number, U8Fixed8Number,   UInt16Number,
    |  > UInt32Number,     UInt64Number,     UInt8Number, 
    |  > XYZNumber
    :: ITagType
       # v2
       > CHRM, CRDI, CURV, DATA, DTIM, DEVS, MFT2,
       > MFT1, MEAS, NCOL, NCL2, PSEQ, RCS2, SF32,
       > SCRN, SIG_, DESC, TEXT, UF32, BFD_, UI16,
       > UI32, UI64, UI08, VIEW, XYZ_,
       # v4
       > CLRO, CLRT, MAB_, MBA_, MLUC, PARA,

=end

require 'expack'
require 'icc/utils'
require 'icc/constants'
require 'icc/header'
require 'icc/tagtable'
require 'icc/types'
require 'icc/tagdata'

#
# ICC class
#

class ICC
  #
  # ICC Class Methods Definition
  #
  def initialize
    @fh       = nil
    @data     = ""
    @header   = nil
    @tagtable = nil
    @tags     = nil
  end

  #
  # ICC::load
  # Generate Reader Object
  # 
  def load(filename)
    File.open(filename, "rb") do |fh|
      @header   = HeaderReader.new   fh
      @tagtable = TagTableReader.new fh
      @tags     = TagDataReader.new  fh, @tagtable
    end
  end
    
  #
  # ICC::create
  # Generate Writer Object
  # 
  def create(filename, options = {}, &block)
    rescueflag = false
    File.open(filename, "wb") do |fh|
      @fh = fh
      begin
        @header   = HeaderWriter.new
        @tagtable = TagTableWriter.new
        @tags     = TagDataWriter.new @tagtable

        yield self
        @fh.write @data
      rescue
        rescueflag = true
      end
    end
    FileUtils.rm_f(filename) if rescueflag
  end

  #
  # ICC::update
  # Generate Updater Object
  #
  def update
  end

  attr_accessor :header, :tagtable
  alias_method :tag, :tagtable

  ### debug
  def dump
    @data
  end

  def get_tag(tag)
    @tags.get(tag.to_sym)
  end

  def set_tag(tag, data)
  end

end



###############
if $0 == __FILE__
  def main
    icc = ICC.new
    icc.create("test.icc") {|it|
      it.header({:pcs => "XYZ "})
    }
  end

  main
end

