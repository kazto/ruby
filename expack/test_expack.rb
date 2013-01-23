#!/usr/bin/ruby

require 'test/unit'
require 'expack'

class TC_ExPack < Test::Unit::TestCase
  def setup
    @dat = File.open("sRGB Profile.icc","rb").read
    @obj = ExPack.new(@dat)
  end

  def x_test_unpackdsl_1
    ret = @obj.unpackex {
      x128
      v = N()
      v.times {
        [a4, N(), N()]
      }
      
    }
    assert_equal([17, ["cprt", 336, 51], ["desc", 388, 108], ["wtpt", 496, 20], ["bkpt", 516, 20], ["rXYZ", 536, 20], ["gXYZ", 556, 20], ["bXYZ", 576, 20], ["dmnd", 596, 112], ["dmdd", 708, 136], ["vued", 844, 134], ["view", 980, 36], ["lumi", 1016, 20], ["meas", 1036, 36], ["tech", 1072, 12], ["rTRC", 1084, 2060], ["gTRC", 1084, 2060], ["bTRC", 1084, 2060]].flatten,
                 ret
                 )
  end

  def off_test_unpackdsl_2
    ret = @obj.unpackex { "@128Na4NN" }
  end

  def test_unpackdsl_3
    obj = ExPack.new("hoge"*5)
    ret = obj.unpackex { x6a6x1a3 }
    assert_equal(["gehoge","oge"],ret)
  end

  # def txest_unpack_1
  #   assert_equal(@dat.unpackex("@128L[a4LL]"), 
  #                [17, ["cprt", 336, 51], ["desc", 388, 108], ["wtpt", 496, 20], ["bkpt", 516, 20], ["rXYZ", 536, 20], ["gXYZ", 556, 20], ["bXYZ", 576, 20], ["dmnd", 596, 112], ["dmdd", 708, 136], ["vued", 844, 134], ["view", 980, 36], ["lumi", 1016, 20], ["meas", 1036, 36], ["tech", 1072, 12], ["rTRC", 1084, 2060], ["gTRC", 1084, 2060], ["bTRC", 1084, 2060]]
  #                )
  # end

  # def txest_unpack_2
  #   assert_equal(@dat.unpackex("@128L(a4L>L>)@<(a<)"), [17, ["cprt", 336, 51], ["text\000\000\000\000Copyright (c) 1998 Hewlett-Packard Company\000"]])
  # end

  def x_test_pack_1
    obj = ExPack.new([0x30, 0x31, 0x32, 0x33, 0x34])
    ret = obj.packex {
      a5
    }
    assert_equal("01234", ret)
  end

  def test_pack_2
    obj = ExPack.new()
    ret = obj.packex[
      0x30, "c"
    ][
      0x31, "c"
    ][
      0x32, "c"
    ][
      0x33, "c"
    ][
      0x34, "c"
    ].value
    assert_equal("01234", ret)
  end

  def test_pack_operator_squarebrace
    obj = ExPack.new
    ret = obj.packex[[1,2,3], "x4N*"]
    assert_equal("\000\000\000\000\000\000\000\001\000\000\000\002\000\000\000\003",
                 ret.value)
    assert_equal(16, ret.value.size)

    ret = obj.packex[ret.value.size, "N", 0]
    assert_equal("\000\000\000\020\000\000\000\001\000\000\000\002\000\000\000\003",
                 ret.value)
    assert_equal(16, ret.value.size)
  end

  def test_pack_insert_operator_gtgt
    obj = ExPack.new.packex
    [1,2,3].zip(["N","N","N"]) do |v|
      obj << v
    end

    assert_equal("\000\000\000\001\000\000\000\002\000\000\000\003",
                 obj.value)
    assert_equal(12, obj.value.size)

    obj.insert(obj.value.size + 4, "N", 0)
    assert_equal("\000\000\000\020\000\000\000\001\000\000\000\002\000\000\000\003",
                 obj.value)
    assert_equal(16, obj.value.size)
  end
end

