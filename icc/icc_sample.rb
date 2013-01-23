#!/usr/bin/ruby

require 'test/unit'
require 'icc'
require 'fileutils'

class TC_ICC < Test::Unit::TestCase
  # def setup
  # end

  def teardown
    if FileTest.exist? "test.txt"
      FileUtils.rm "test.txt"
    end
  end
  
  def test_create
    adobergb = ICC.new
    adobergb.create("adobergb.icc") {|it|
      it.header.set({ :prefer     => "adbe",
                      :class      => "mntr",
                      :colorspace => "rgb ",
                      :pcs        => "xyz ",
                      :whitepoint => ICC::D50,
                    })

      xyz = 
      [[0.610, 0.311, 0.019],
       [0.205, 0.626, 0,061],
       [0.149, 0.063, 0.745]]
      it.tag =
      [
       ICC::DESC("Ruby ICC Class"),
       ICC::CPRT("Ruby ICC Class"),
       ICC::RXYZ(xyz),
       ICC::GXYZ(xyz),
       ICC::BXYZ(xyz),
       ICC::RTRC(ICC::Gamma(2.199)),
       ICC::GTRC(ICC::Gamma(2.199)),
       ICC::BTRC(ICC::Gamma(2.199)),
      ]
      # saved at closing block
    }
  end

  def test_read_header
    srgb = ICC.new
    srgb.load("sRGB Profile.icc")

    # p srgb.header.dump
    assert_kind_of(ICC::HeaderReader,   srgb.header)

    # $stderr.puts "----"
    # $stderr.puts srgb.header.inspect
    # $stderr.puts "----"

    assert_equal(3144,                  srgb.header.size)        
    assert_equal("Lino",                srgb.header.prefered_cmm)
    assert_equal(0x2100000,             srgb.header.icc_version) 
    assert_equal("mntr",                srgb.header.device_class)
    assert_equal("RGB ",                srgb.header.color_space) 
    assert_equal("XYZ ",                srgb.header.pcs)         
    assert_equal([1998,2,9,6,49,0],     srgb.header.created)     
    assert_equal("MSFT",                srgb.header.platform)    
    assert_equal(0,                     srgb.header.icc_flag)    
    assert_equal("IEC ",                srgb.header.manufacturer)
    assert_equal("sRGB",                srgb.header.device_model)
    assert_equal([0,0],                 srgb.header.attributes)  
    assert_equal(0,                     srgb.header.intent)      
    assert_equal([63190, 65536, 54061], srgb.header.illuminant)  
    assert_equal("HP  ",                srgb.header.creator)     
  end

  def test_read_tag
    srgb = ICC.new
    srgb.load("sRGB Profile.icc")

    assert_kind_of(ICC::TagTableReader, srgb.tag)
    assert_equal(17,                    srgb.tag.size)
    assert_equal(208,                   srgb.tag.binsize)
    assert_equal([ :cprt, :desc, :wtpt, :bkpt,
                   :rXYZ, :gXYZ, :bXYZ, :dmnd,
                   :dmdd, :vued, :view, :lumi,
                   :meas, :tech, :rTRC, :gTRC, :bTRC],
                 srgb.tag.signatures)
    assert_kind_of(ICC::ITagTable::Element, srgb.tag[:lumi])
    assert_equal(:lumi,                     srgb.tag[:lumi].signature)
    assert_equal(1016,                      srgb.tag[:lumi].offset)
    assert_equal(20,                        srgb.tag[:lumi].size)
    assert_equal([:desc, 388,  108],        srgb.tag[:desc].to_a)
    assert_equal([:wtpt, 496,  20],         srgb.tag[:wtpt].to_a)
    assert_equal([:bTRC, 1084, 2060],       srgb.tag[:bTRC].to_a)
  end

  def test_iccutil_inumerictype
    orival = [1998,2,9,6,49,0]
    encval = ICC::NumericType::DateTimeNumber.new(orival).encode
    decval = ICC::NumericType::DateTimeNumber.new(encval).decode
    assert_equal(orival, decval)
    assert_equal("\a\316\000\002\000\t\000\006\0001\000\000",
                 encval)

    orival = [0x1234, 0x5678]
    encval = ICC::NumericType::Response16Number.new(orival).encode
    decval = ICC::NumericType::Response16Number.new(encval).decode
    assert_equal(orival, decval)
    assert_equal("\0224\000\000\000\000Vx",encval)
  end

  def test_read_tagdata
    srgb = ICC.new
    srgb.load("sRGB Profile.icc")

    wtpt = srgb.get_tag(:wtpt)
    assert_kind_of(ICC::TagType::XYZ_, wtpt)
    assert_equal("wtpt",      wtpt.signature)
    assert_equal("XYZ ",      wtpt.tagtype)
    assert_equal(["x", "y", "z"],
                 wtpt.keys)
    assert_equal(["XYZ ", 62289, 65536, 71372], wtpt.data)
    assert_equal(62289, wtpt.x)
    assert_equal(65536, wtpt.y)
    assert_equal(71372, wtpt.z)
  end

  def test_write_header
    File.open("test.txt","wb") do |fh|
      hdw = ICC::HeaderWriter.new(fh)
      raw = hdw.to_bin
      assert_equal(128, raw.size)
      assert_equal("\000\000\000\000appl@\000\000\000mntrRGB XYZ \a\334\000\f\000\031\000\f\000\000\000\000acpsMSFT\000\000\000\000ricc    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\366\326\000\001\000\000\000\000\323-ricc\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000", raw)
    end
  end

  def _test_update
    icc = ICC.new
    icc.update("adobergb.icc") {
      rtrc = icc.tag[:rTRC]
      tag[:rTRC] = rtrc * 0.9
    }

    p icc.tag[:rTRC]        # => ICC::Gamma(1.9790999999999999)
  end

end

