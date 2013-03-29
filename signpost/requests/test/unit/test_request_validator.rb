# Unit tests for HTTPValidator::RequestValidator
#
# NOTE: will generate test coverage numbers in the 'coverage'
# directory under the current directory from which the
# run started.
#

begin
  require 'simplecov'
  SimpleCov.start
rescue LoadError
  puts 'Coverage disabled, enable by installing simplecov'
end

$:.unshift "#{File.dirname(__FILE__)}/../.."
require 'log_simple'
require 'request_validator'
require 'walker'
require 'test/unit'

class TestRequestValidator < Test::Unit::TestCase
  
  # Tests for the validation methods of RequestValidator.

  # Create the logger
  def setup
    @log = LogSimple.instance.logger(true)
  end
  
  def test_valid_request_method
    val = HTTPValidator::RequestValidator.new(@log)
    assert(val.valid_request_method?('GET'))
    assert(val.valid_request_method?('POST'))

    assert(!val.valid_request_method?('get'))
    assert(!val.valid_request_method?('post'))
    assert(!val.valid_request_method?('HEAD'))
    assert(!val.valid_request_method?('FOOT'))
    assert(!val.valid_request_method?(''))
    assert(!val.valid_request_method?(nil))
  end

  def test_valid_http_version
    val = HTTPValidator::RequestValidator.new(@log)
    assert(val.valid_http_version?('1.1'))

    assert(!val.valid_http_version?(''))
    assert(!val.valid_http_version?(' '))
    assert(!val.valid_http_version?('HTTP'))
    assert(!val.valid_http_version?('HTTP/'))
    assert(!val.valid_http_version?('HTTP/1'))
    assert(!val.valid_http_version?('HTTP/1.'))
    assert(!val.valid_http_version?('HTTP/1.0'))
    assert(!val.valid_http_version?('HTTP/2.1'))
    assert(!val.valid_http_version?('HTTP/1.2'))
    assert(!val.valid_http_version?('1.2'))
    assert(!val.valid_http_version?('1.0'))
  end
  
  def test_valid_url
    val = HTTPValidator::RequestValidator.new(@log)
    assert(val.valid_uri?('/'))
    assert(val.valid_uri?('/some/stuff'))
    assert(val.valid_uri?('../../some/stuff'))
    
    assert(!val.valid_uri?(''))
    assert(!val.valid_uri?('http://www.www.com'))
  end
  
  def test_valid_header
    val = HTTPValidator::RequestValidator.new(@log)
    assert(val.valid_header?({}))
    assert(val.valid_header?({'accept' => ['some stuff']}))
    assert(val.valid_header?({'accept' => ['some stuff'], 'host' => ['wiggle.worm'], 'referer' => ['http://www.cnn.com/']}))
    
    assert(!val.valid_header?({'Accept' => ['some stuff']}))
    assert(!val.valid_header?({'other' => ['some stuff']}))
    assert(!val.valid_header?({'accept' => ['']}))
    assert(!val.valid_header?({'accept' => 'thingie'}))
    assert(!val.valid_header?('accept'))
  end

  def test_valid_body
    val = HTTPValidator::RequestValidator.new(@log)
    assert(val.valid_body?(''))
    assert(val.valid_body?('<'))
    assert(val.valid_body?('<head>'))
    assert(val.valid_body?('<html><head><body><body></body></head></html>'))
    assert(val.valid_body?(nil))
  end
  
  def test_valid_request
    # Check all the files in ../data
    test_data_dir = "#{File.dirname(__FILE__)}/../data"
    dir = Dir.new(test_data_dir)
    dir.each { |file_name|
      # Skip hidden and ruby files
      next if file_name =~ /^\./    
      path = "#{test_data_dir}/#{file_name}"      
      # Make sure it is a file and not something else
      next unless File.file?(path)
      # Validate the file and print results
      validator = HTTPValidator::RequestValidator.new(@log)
      validator.valid_request?(path)
    }
  end
  
  def test_valid_request_extra
    # Run a test of a POST operation with flag to report missing content-length
    # and with verbose on so we hit some extra code paths.  Also fetch the
    # errors array so that is covered as well.
    old_out = $stdout
    $stdout = File.new('/dev/null', 'w')
    test_data_dir = "#{File.dirname(__FILE__)}/../data"
    validator = HTTPValidator::RequestValidator.new(@log, true)
    validator.valid_request?("#{test_data_dir}/valid_post.request")
    puts validator.errors().inspect
    $stdout.close
    $stdout = old_out
  end
end

class TestRequestValidator < Test::Unit::TestCase
  # Tests for the validation methods of RequestValidator.

  TEST_DATA_DIR = "#{File.dirname(__FILE__)}/../data"
  
  # Create the logger
  def setup
    @log = LogSimple.instance.logger(true)
  end

  def test_walker_len_not_required
    walker = HTTPValidator::Walker.new(@log, false)
    assert(walker.walk TEST_DATA_DIR)
    stats = walker.stats.to_s
    assert(stats == "{:examined=>33, :valid=>14, :invalid=>16, :skipped=>3}")
  end

  def test_walker_len_required
    walker = HTTPValidator::Walker.new(@log, true)
    assert(walker.walk TEST_DATA_DIR)
    stats = walker.stats.to_s
    assert(stats == "{:examined=>33, :valid=>9, :invalid=>21, :skipped=>3}")
 end
  
  def test_walker_not_file
    walker = HTTPValidator::Walker.new(@log, true)
    assert(!walker.walk('/dev/null'))
  end
end  
