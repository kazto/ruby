#!/usr/bin/ruby

=begin
ExPack Module
Array::pack, String::unpack を拡張する

 * 読んだ値をレジスタに保管する
 * 保管した値を使う
 * 繰り返す

=specification



format_string = "@128La4L>L>@<(a<)"
origin_data   = File.open("sRGB profile.icc","rb").read
origin_data.unpackex(format_string)
  # => ["text\000\000\000\000Copyright (c) 1998 Hewlett-Packard Company\000"]



obj = ExPack.open(file, mode)
obj.unpackex do
  x128
  _n * {
    a4.L.L
  }

end




=end

class ExPackInterface
  @@TypeSizeTable = {
    :a => 1, :A => 1, :b => 1, :B => 1, :c => 1, :C => 1, 
    :d => 8, :D => 8, :e => 8, :E => 8, :f => 4, :F => 4, 
    :g => 4, :G => 8, :h => 1, :H => 1, :i => 4, :I => 4, 
    :l => 4, :L => 4, :m => 1, :M => 1, :n => 2, :N => 4, 
    :q => 8, :Q => 8, :s => 2, :S => 2, :v => 2, :V => 4, 
  }
end


class ExPack < ExPackInterface

  def initialize(dat = "", pos = 0)
    @dat = dat
    @pos = pos.to_i
    @unpacked = []
    @packer = nil
  end

  def load(dat, pos = 0)
    @dat = dat
    @pos = pos.to_i
  end

  def self.open(file, mode)
    dat = File.open(file,mode).read
    self.new(dat)
  end

  def debug_p(v)
    # $stderr.puts v.inspect
    p v
  end

  def data
    @unpacked
  end

  def _method_missing_impl(meth, *arg, &block)
    str = meth.to_s
    cmds = str.scan(/(_?[[:alpha:]@])([[:digit:]]*)/)
    cmds.each do |cmd|
      nm, na = cmd
      nm = "_at_" if cmd[0] == "@"

#      debug_p nm
#      debug_p na
      if(self.class.method_defined?(nm))
        begin
          na = na.to_i
          na = 1 if na < 1
        rescue
          na = 1
        end
        v = __send__(nm, na)
      else
        return :method_missing
      end
    end
  end

  def unpackex(&block)
    ret = self.instance_eval(&block)
    if(ret.is_a? String)
      _method_missing_impl(ret)
    end
    @unpacked
  end

  def method_missing(meth, *arg, &block)
    ret = _method_missing_impl(meth, *arg, &block)
    if(ret == :method_missing)
      super meth, *arg, &block
    else
      ret
    end
  end

  def _at_(v=1)
    @pos = v.to_i
    nil
  end

  def _check_return_v(v,pos)
    if (v.nil? or v.size < 1) 
      nil
    else
      @pos += pos
      v
    end
  end
  
  def _unpack_dat(v, tmpl, sz)
    r = _check_return_v(@dat[@pos..-1].unpack("#{tmpl.to_s}#{v}"), sz*v.to_i)
    if r.nil?
      return nil
    elsif r.is_a? Array
      if r.size == 1
        @unpacked.concat( r )
      else
        @unpacked << r
      end
    else
      raise "#{__FILE__}:#{__LINE__}: unexpected result..."
    end
    return *r
  end

  def x(v=1)
    @pos += v.to_i
    nil
  end

  @@TypeSizeTable.each do |k,v|
    define_method(k) do |arg|
      arg = 1 if arg.nil?
      _unpack_dat(arg, k, v)
    end
  end

  private :_method_missing_impl, :_unpack_dat, :_check_return_v, :_at_

  #
  # pack class
  #
  class Packer
    def initialize(data = nil)
      @packed = ""
      @pos = 0
    end

    def [](value, format, pos = nil)
      # $stderr.puts "======="
      # $stderr.puts value
      # $stderr.puts format
      # $stderr.puts pos
      # $stderr.puts "======="

      _pack_value(value, format, pos) do |selfobj, packed|
        selfobj.packed[pos, packed.size] = packed
      end
    end

    def <<(arg)
      if(arg.is_a? Array)
        arg.each_slice(2) do |value, format|
          self[value, format]
        end
      end
      self
    end

    def insert(value, format, pos)
      _pack_value(value, format, pos) do |selfobj, packed|
        selfobj.packed.insert(pos, packed)
        selfobj._set_pos(selfobj.pos + packed.size)
      end
    end

    def _pack_value(value, format, pos = 0, &block)
      packed = Array(value).pack(format)
      return self if packed.nil?

      if(pos.is_a? Numeric and pos.abs <= @packed.size)
        yield(self, packed)
      else
        @packed << packed
        @pos += packed.size
      end
      self
    end

    def _set_pos(pos)
      @pos = pos
    end

    attr_reader :packed, :pos
    alias_method :value, :packed
    private :_pack_value, :_set_pos
  end

  def packex *args, &block
    if @packer.nil?
      @packer = Packer.new @data
    end

    if block_given?
      block.call
    else
      @packer
    end
  end
end

