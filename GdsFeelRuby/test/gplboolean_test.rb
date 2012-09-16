# To change this template, choose Tools | Templates
# and open the template in the editor.

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'gpl_data'

class GPLTrueTest < Test::Unit::TestCase
  def test_gexpr
    ds = GPL::TRUE
    assert_equal '1', ds.gexpr
  end

  def test_rank
    ds = GPL::TRUE
    assert_equal 1, ds.rank
  end

  def test_size
    ds = GPL::TRUE
    assert_equal 1, ds.size
  end

  def test_length
    ds = GPL::TRUE
    assert_equal 1, ds.length
  end

  def test_type
    ds = GPL::TRUE
    assert_equal "LOGICAL", ds.type
  end

  def test_mode
    ds = GPL::TRUE
    assert_equal 1, ds.mode
  end

end

class GPLFalseTest < Test::Unit::TestCase
  def test_gexpr
    ds = GPL::FALSE
    assert_equal '0', ds.gexpr
  end

  def test_rank
    ds = GPL::FALSE
    assert_equal 1, ds.rank
  end

  def test_size
    ds = GPL::FALSE
    assert_equal 1, ds.size
  end

  def test_length
    ds = GPL::FALSE
    assert_equal 1, ds.length
  end

  def test_type
    ds = GPL::FALSE
    assert_equal "LOGICAL", ds.type
  end

  def test_mode
    ds = GPL::FALSE
    assert_equal 1, ds.mode
  end

end
