# Unit tests for SimpleTime::add_minutes
#
# NOTE: will generate test coverage numbers in the 'coverage'
# directory under the current directory from which the
# run started.
#

begin
  require 'simplecov'
  SimpleCov.start
rescue LoadError
  puts 'Test coverage generation disabled, enable by installing simplecov'
end

$:.unshift "#{File.dirname(__FILE__)}/../.."
require 'simple_time'
require 'test/unit'

class TestSimpleTime < Test::Unit::TestCase
  
  # Tests for the validation methods of RequestValidator.

  def check(actual, expected)
    assert(actual == expected, "#{caller[0]}: actual: #{actual}, expected: #{expected}")
  end

  def test_add_minutes_successfully
    check(SimpleTime::add_minutes('12:00 AM', 0), '12:00 AM')
    check(SimpleTime::add_minutes('12:00 AM', 1), '12:01 AM')
    check(SimpleTime::add_minutes('12:09 AM', 1), '12:10 AM')
    check(SimpleTime::add_minutes('12:59 AM', 1), '01:00 AM')
    check(SimpleTime::add_minutes('01:00 AM', 1), '01:01 AM')
    check(SimpleTime::add_minutes('01:59 AM', 1), '02:00 AM')
    check(SimpleTime::add_minutes('11:59 AM', 1), '12:00 PM')

    check(SimpleTime::add_minutes('11:59 PM', 1), '12:00 AM')
    check(SimpleTime::add_minutes('12:00 PM', 0), '12:00 PM')
    check(SimpleTime::add_minutes('12:00 PM', 1), '12:01 PM')
    check(SimpleTime::add_minutes('12:09 PM', 1), '12:10 PM')
    check(SimpleTime::add_minutes('12:59 PM', 1), '01:00 PM')
    check(SimpleTime::add_minutes('01:00 PM', 1), '01:01 PM')
    check(SimpleTime::add_minutes('01:59 PM', 1), '02:00 PM')
    check(SimpleTime::add_minutes('11:59 PM', 1), '12:00 AM')
  end

  def test_input_error_detection
    # '00' hours is not supported in U.S.A
    assert_raise ArgumentError do
      SimpleTime::add_minutes('00:00 AM', 0)
    end
    assert_raise ArgumentError do
      SimpleTime::add_minutes('00:60 AM', 1)
    end
    assert_raise ArgumentError do
      SimpleTime::add_minutes('13:59 AM', 1)
    end
    assert_raise ArgumentError do
      SimpleTime::add_minutes(':59 AM', 1)
    end
    assert_raise ArgumentError do
      SimpleTime::add_minutes('1: AM', 1)
    end
    assert_raise ArgumentError do
      SimpleTime::add_minutes('1:1 AM', 1)
    end
    assert_raise ArgumentError do
      SimpleTime::add_minutes('', 0)
    end
    assert_raise ArgumentError do
      SimpleTime::add_minutes(nil, 0)
    end
    assert_raise ArgumentError do
      check(SimpleTime::add_minutes('01:52 AM', nil))
    end
    assert_raise ArgumentError do
      SimpleTime::add_minutes('01:52 AM', 'abc')
    end
    assert_raise ArgumentError do
      SimpleTime::add_minutes('01:52 AM', '02:24 PM')
    end
    assert_raise ArgumentError do
      SimpleTime::add_minutes('01:52 AM', 3.14)
    end
    assert_raise ArgumentError do
      SimpleTime::add_minutes('01:52 AM', Integer)
    end
  end
  
  def test_big_minutes
    # Add a day
    check(SimpleTime::add_minutes('07:00 AM', 1440), '07:00 AM')
    # Add a week
    check(SimpleTime::add_minutes('07:00 AM', 1440 * 7), '07:00 AM')
    # Add a year
    check(SimpleTime::add_minutes('07:00 AM', 1440 * 7 * 365), '07:00 AM')
  end
  
  def test_add_negative
    check(SimpleTime::add_minutes('07:00 AM', -1), '06:59 AM')
    check(SimpleTime::add_minutes('07:00 AM', -60), '06:00 AM')
    check(SimpleTime::add_minutes('12:00 AM', -1), '11:59 PM')
    check(SimpleTime::add_minutes('12:00 PM', -1), '11:59 AM')
  end
  
  def test_whitespace
    check(SimpleTime::add_minutes(' 07:00 AM', -1), '06:59 AM')
    check(SimpleTime::add_minutes('   07:00 AM', -1), '06:59 AM')
    check(SimpleTime::add_minutes('07:00  AM', -1), '06:59 AM')
    check(SimpleTime::add_minutes('07:00    AM', -1), '06:59 AM')
    check(SimpleTime::add_minutes('07:00AM', -1), '06:59 AM')
    check(SimpleTime::add_minutes('07:00 AM ', -1), '06:59 AM')
    check(SimpleTime::add_minutes('07:00 AM    ', -1), '06:59 AM')
  end
  
  def test_case
    check(SimpleTime::add_minutes('07:00 am', -1), '06:59 am')
    check(SimpleTime::add_minutes('07:00 aM', -1), '06:59 aM')
    check(SimpleTime::add_minutes('07:00 Am', -1), '06:59 Am')
    check(SimpleTime::add_minutes('07:00 pm', -1), '06:59 pm')
    check(SimpleTime::add_minutes('07:00 pM', -1), '06:59 pM')
    check(SimpleTime::add_minutes('07:00 Pm', -1), '06:59 Pm')
    check(SimpleTime::add_minutes('11:59 am', 1), '12:00 pm')
    check(SimpleTime::add_minutes('11:59 pm', 1), '12:00 am')
    check(SimpleTime::add_minutes('12:00 pm', -1), '11:59 am')
    check(SimpleTime::add_minutes('12:00 am', -1), '11:59 pm')
  end
  
  def test_digits
    check(SimpleTime::add_minutes('7:00 PM', -1), '6:59 PM')
    check(SimpleTime::add_minutes('9:59 AM', 1), '10:00 AM')
  end
end
