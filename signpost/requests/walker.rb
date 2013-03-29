
# HTTPValidator: a module containing classes for
# validating HTTP requests
module HTTPValidator

  # Iterate over a filtered list of files in the directory given,
  # passing each accepted file to RequestValidator.
  # - filters out non-files and ruby files
  # - collects simple statistics about activity
  class Walker
    
    # Constructor:
    # * log: Logger for output
    def initialize(log, length_required = false)
      @log = log
      @length_required = length_required
      # Initialize hash for collecting statistics
      @stats = {:examined => 0, :valid => 0, :invalid => 0, :skipped => 0}
    end

    # Access to statistics collected 
    def stats
      return @stats
    end
    
    # Validate each file in the given directory that does not end in ".rb"
    # (non-files are omitted)
    # * directory: the directory to be examined
    def walk(directory)
      # Remove trailing / if any
      directory = directory.chomp('/')
      @log.debug "Examining directory #{directory}"

      # Must have a directory
      unless File.directory?(directory)
        @log.error "Skipping, not a directory: #{directory}"
        @stats[:skipped] += 1
        return false
      end
      
      # Walk the directory, checking each file that is not hidden or a Ruby source file
      Dir.new(directory).each { |file_name|
        stats[:examined] += 1
        path = "#{directory}/#{file_name}"
        @log.debug "Examining: #{path}"

        # Skip hidden and ruby files
        if file_name =~ /^\./ || file_name =~ /\.rb$/
          @log.debug"#{path}: skipped"
          stats[:skipped] += 1
          next
        end
          
        # Make sure it is a file and not something else
        unless File.file?(path)
          @log.warn "Not a file: #{path}"
          stats[:skipped] += 1
          next
        end
    
        # Validate the file and print results
        validator = RequestValidator.new(@log, @length_required)
        if validator.valid_request?(path)
          @log.info "#{path} is valid"
          stats[:valid] += 1
        else
          @log.info "#{path}: #{validator.errors.join(", ")}"
          stats[:invalid] += 1
        end      
      }
      return true
    end # walk
  end #class
end # module

