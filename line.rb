#!/usr/bin/env ruby
# vim: ts=2 sw=2

require 'point'

class AbstractLine
  def self.has_endpoint?
    false
  end

  def length
    return 0.0
  end
end

class StrightLine < AbstractLine
  @stread_point

  def length
    return 1e99999
  end
end

class SegmentLine < AbstractLine
  def self.has_endpoint?
    true
  end

  def length
    @length
  end

  def length=(value)
    @length
  end
end

