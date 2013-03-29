require 'singleton'
require 'logger'

# Logger: simple wrapper for standard Ruby logger; could be much more complex
# Using Singleton since we want only one logger for the program
class LogSimple  
  include Singleton
  
  # Constructor: create the Ruby logger
  def initialize
    @log = Logger.new(STDOUT)
  end
  
  # Obtain the logger configured as we like
  # * verbosity: true for debug output
  def logger(verbosity = false)
    verbose(verbosity)
    return @log
  end
  
  private
  
  # Set the noise level
  # * verbosity: true for debug output
  def verbose(verbosity)
    @log.level = verbosity ? Logger::DEBUG : Logger::INFO
  end

end