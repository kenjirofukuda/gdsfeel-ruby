# To change this template, choose Tools | Templates
# and open the template in the editor.

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'gpl_data'

class GPLNullTest < Test::Unit::TestCase
  def test_gexpr
    ds = GPL::NULL
    assert_equal '""', ds.gexpr
  end

  def test_rank
    ds = GPL::NULL
    assert_equal 1, ds.rank
  end

  def test_size
    ds = GPL::NULL
    assert_equal 0, ds.size
  end

  def test_length
    ds = GPL::NULL
    assert_equal 1, ds.length
  end

  def test_type
    ds = GPL::NULL
    assert_equal "NULL", ds.type
  end

end
