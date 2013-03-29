#!/usr/bin/env ruby
#Usage: validator.rb [options] dir ...
#	Checks that all files in the directory list given are valid requests.
#	(Hidden files and files ending in ".rb" are omitted.)
#Options:
#    -l, --[no-]length-required       Require that POST requests contain a content-length header
#    -v, --[no-]verbose               Verbose output
#    -h, --help                       Print help

$:.unshift File.dirname(__FILE__)
require 'rubygems'
require 'optparse'
require 'log_simple'
require 'walker'
require 'request_validator'

# Parse command line

# Hash of command line options (global)
options = {}

parser = OptionParser.new do |opts|
  
  opts.banner = "Usage: #{File.basename($0)} [options] dir ...
\tChecks that all files in the directory list given are valid requests.
\t(Hidden files and files ending in \".rb\" are omitted.)
Options:"
  
  opts.on("-l", "--[no-]length-required", "Require that POST requests contain a content-length header") do |l|
    options[:length_required] = l
  end
  
  opts.on("-v", "--[no-]verbose", "Verbose output") do |v|
    options[:verbose] = v
  end

  opts.on("-h", "--help", "Print help") do |h|
    options[:help] = h
  end
  
end # parser

parser.parse!

# Create logger
log = LogSimple.instance.logger(options[:verbose])


# Print help if requested
if options[:help]
  log.info parser.help
  exit(0)
end

# Make sure we have at least one directory else print instructions
if ARGV.length == 0
  log.info parser.help
end

# Prepare to walk the directory list
walker = HTTPValidator::Walker.new(log)

# For each directory in the argument list...
ARGV.each {|directory|
  walker.walk(directory)
}

stats = walker.stats

log.info "#{stats[:examined]} examined, #{stats[:skipped]} skipped, #{stats[:valid]} valid, #{stats[:invalid]} invalid"

exit(0)

