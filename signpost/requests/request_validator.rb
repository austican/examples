#!/usr/bin/env ruby

require 'webrick'

module HTTPValidator


# Signpost's Offer Exchange (SOX), an industry leading marketplace for daily deals day trading, has been
# experiencing outages over the past few months which have been attributed to an influx of malformed HTTP
# requests from high-frequency traders Goldstone Bags and Blueman Group. As such, we've decided to have
# you implement a basic request validator based upon a simplified version of the HTTP 1.1 specification.
# A request must meet the following criteria to be considered valid:
# * A request line consisting of a method, path, and version separated by whitespace
#   - Method: "GET" or "POST"
#   - Path: Any relative path, e.g., "/offer/1"
#   - Version: "HTTP/1.1"
# * Zero or more headers consisting of a name and value separated by a colon
#   - Name: "Accept", "Host", or "Referer"
#   - Value: One or more characters
# * One blank line
# * A body consisting of zero or more characters
# 
# All characters will be considered 8-bit ASCII and all lines end with CRLF (characters 0x0D, 0x0A)
#
############################################
# NOTE: A valid POST will contain a Content-Length header.  Since this header is not listed above we supress such
# errors unless asked to display them.
#############################################
class RequestValidator
  
  # Valid request methods
  VALID_REQUEST = %w{GET POST} unless defined? VALID_REQUEST
  
  # Valid HTTP version
  VALID_HTTP_VERSION = '1.1' unless defined? VALID_HTTP_VERSION
  
  # Valid set of header names
  VALID_HEADER_NAME = %w{accept host referer} unless defined? VALID_HEADER_NAME # webrick normalizes to lower-case
  
  # Minimum length of a header value
  MIN_HEADER_VALUE_LENGTH = 1 unless defined? MIN_HEADER_VALUE_LENGTH
  
  # Constructor:
  # * log: the logger
  # * length_required: true if we require that POST requests contain a content-length header
  def initialize(log, length_required = false)
    @log = log
    @length_required = length_required
    # The request parser
    @req = WEBrick::HTTPRequest.new(WEBrick::Config::HTTP)
    # Array of error messages describing errors found
    @errors = []
  end

  # Validate that all required request components are present and correct
  def valid_request?(file_name)
    @log.debug "Validating #{file_name}"
    valid = true # Assume valid input until proven invalid
    @errors = []
    # Must be able to read the file
    valid = invalid("File not readable: #{file_name}") unless File.readable?(file_name)
    # File too small to contain valid input (s/b < "GET / HTTP/1.1".length?)
    valid = invalid("Zero length file: #{file_name}") unless File.size(file_name) > 0
    if valid
      # Passed previous tests, proceed with parsing the file
      File.open(file_name) do |socket|
        begin
          @req.parse(socket)
          valid &= valid_request_method?(@req.request_method)
          valid &= valid_http_version?(@req.http_version.to_s)
          valid &= valid_header?(@req.header)
          begin
            # A valid POST request contains a content-length header but the spec does not
            # require one.  We catch the exception and emit an error message if allowed
            valid &= valid_body?(@req.body)
          rescue WEBrick::HTTPStatus::LengthRequired => e
            if @length_required
              valid = false
              @errors << "Length header required for POST"
            else
              valid &= true
            end
          end
        # The request line (first line) is in error.  Since
        # parsing stops here, this is the only error we'll get
        # for this file
        rescue WEBrick::HTTPStatus::BadRequest => e
            valid = false
            @errors << e.message
        # Something unexpected happend so log it and continue
        # Note: this code is hard to test since it depends on
        # an unplanned error condition
        rescue Exception => e
          @log.error "Exception while processing #{file_name}: #{e.inspect}"
          @log.error e.backtrace
          valid = false
          @errors << e.message
        end
      end
    end
    @log.debug "Validation of #{file_name} #{valid ? 'passed' : 'failed'}"
    return valid
  end
  
  # Return array of errors (may be empty)
  def errors
    # Return array of error messages
    @errors
  end

  # Validate the HTTP request method
  def valid_request_method?(request_method)
    @log.debug "Validating request method: #{request_method}"
    unless VALID_REQUEST.include?(request_method)
      return invalid("Invalid request method: #{request_method}")
    end
    @log.debug "Request method is valid"
    return true
  end
  
  # Validate the HTTP version
  def valid_http_version?(request_http_version)
    @log.debug "Validating HTTP version: #{request_http_version}"
    unless VALID_HTTP_VERSION == request_http_version
      return invalid("Invalid HTTP request version: #{request_http_version}")
    end
    @log.debug "HTTP version is valid"
    return true
  end
  
  # Valiate that the URI is relative and not absolute
  def valid_uri?(uri)
    @log.debug "Validating URI: #{uri}"
    # URI required to be relative, reject absolute URI
    return invalid("URI is not valid: #{uri}") if uri =~ /:\/\// # Contains "://"
    return invalid("URI is empty") if uri == ''
    @log.debug "URI is valid"
    return true
  end
  
  # Validate header which contains zero or more key/value pairs of
  # a specified set of header names whose values are of a specified
  # length or longer
  def valid_header?(headers)
    @log.debug "Validating headers: #{headers.inspect}"
    result = true # Assume ok and prove invalid
    return invalid "Incorrect argument" unless headers.kind_of?(Hash)
    headers.each {|name, value|
      @log.debug "Validating header: name=#{name}, value=#{value.inspect}"
      # An acceptably named header
      if VALID_HEADER_NAME.include?(name)
        @log.debug "Header name is valid: #{name}"
        if value.kind_of?(Array)
          value.each {|v|
            # Validate length of each element of value array
            if v.length < MIN_HEADER_VALUE_LENGTH
              result = invalid("Value ('#{v}') for header '#{name}' too short at #{v.length} characters")
            end
          }
        else
          result = invalid("Value for name, '#{name}', is not an array: #{value.inspect}")
        end
      else
        # Bogus header name
        result = invalid("Invalid header: #{name}")
      end
      }
      
    @log.debug "Header validation #{result ? 'successful' : 'failed'}"
    return result
  end
  
  # Body can be zero or more characters so nothing to test
  def valid_body?(body)
    @log.debug "Null test for body"
    return true
  end
  
  # Report an invalid file with reason
  def invalid(message)
    @log.debug message
    @errors << message
    return false
  end
  
end

end
