# SimpleTime provides a method, SimpleTime::add_minutes, to add a number of
# minutes to a time, where the time is given in a format like "HH:MM <A|P>M".
# * The leading hour is optional so "9:15 AM" is accepted.  The returned value
#   mimics the input; a single digit hour is output if one is input, a two-digit
#   is output if a two-digit hour is input.
# * The minutes must be 2 digits.
# * The input's AM/PM indicator is case-insensitive and the output mirrors the
#   input's case even if there is a change from AM to PM.
# * The number of minutes to add is either an Integer a class that derives from
#   Integer.  The value can be positive or negative.
# * The calculation wraps around the clock. Adding a week to 10:00 AM will result in 10:00 AM.
# As described in http://en.wikipedia.org/wiki/12-hour_clock, '12:00 AM' is 
# midnight, not 00:00 and a "0" hour is not accepted.
class SimpleTime
  
  # Add minutes to a time string in the format '{H}H:MM {A|P}M'
  # [time_string] the string to be added
  # [minutes] the number of minutes to add
  # Exceptions: ArgumentError when inputs are invalid
  def self.add_minutes(time_string, minutes)
    # Validate inputs
    time_string, minutes = validate(time_string, minutes)
    # Convert time_string to minutes
    ts_minutes = self.to_minutes(time_string)
    raise ArgumentError.new("Invalid time string: '#{time_string}'") if ts_minutes.nil?
    # Add minutes
    ts_minutes[:total_minutes] += minutes
    # Convert back to time_string format
    self.to_string(ts_minutes)
  end
  
  private
  
  # Days on Earth have ~24 hours
  HOURS_PER_DAY = 24 unless defined? HOURS_PER_DAY
  
  # Always 60 minutes per hour (even on Gallifrey?)
  MINUTES_PER_HOUR = 60 unless defined? MINUTES_PER_HOUR
  
  # Minutes in a day
  MINUTES_PER_DAY = (HOURS_PER_DAY * MINUTES_PER_HOUR) unless defined? MINUTES_PER_DAY
  
  # Maximum hour value allowed in input
  MAX_HOUR = 12 unless defined? MAX_HOUR
  
  # Maximum minute value allowed in input
  MAX_MINUTE = 59 unless defined?  MAX_MINUTE

  # Assure the input parameters are usable, returning them, converted
  # if necessary.
  # [time_string] a non-nill string (parsing is not done here)
  # [minutes] an Integer or something thart can be converted to one.
  # Exceptions: ArgumentError if an argument is invalid
  def self.validate(time_string, minutes)
    # Assure that the time_string is a non-nil string
    raise ArgumentError.new("time is not a string") unless time_string.is_a? String
    # Assure that the minutes is an Integer or can be converted
    unless minutes.is_a? Integer
      raise ArgumentError.new("minutes is not an Integer and could not be converted to one: #{minutes}")
    end
    return time_string, minutes
  end

  # Make the target conform to the same case as the pattern for each character
  # [pattern] a string that determines the case of the target
  # [target] a string whose characters will be set to the same case as the pattern
  # Exception: ArgumentError raised if the strings are of unequal length
  def self.case_like(pattern, target)
    raise ArgumentError.new("Different lengths: '#{pattern}', #{target}'") unless pattern.length == target.length
    result = ''
    target_chars = target.split(//)
    pattern.split(//).each_index{|i|
      original_char = pattern[i]
      if pattern[i] == pattern[i].upcase
        target_chars[i].upcase!
      else
        target_chars[i].downcase!
      end      
      }
    return target_chars.join
  end


  # Convert a string in the form '{H}H:MM {A|P}M' to minutes in the day
  # * Returns the number of minutes, or nil if the input is invalid
  # [time_string] the string containing the time to convert
  # Exception: ArgumentError if the hour or minute values are incorrect
  def self.to_minutes(time_string)
    result = nil
    # Parse into hours, minutes and case insensitive am/pm
    /^\s*([01]?\d):(\d{2})\s*(?i:([ap]m))/.match(time_string) {|match|
      hour_length = match[1].length
      hour = match[1].to_i
      minute = match[2].to_i
      meridiem = match[3]
      
      # Adjustment factor to go from 12 hour AM/PM period to 24 hour period
      raise ArgumentError.new("invalid hour") if hour > MAX_HOUR || hour == 0
      raise ArgumentError.new("invalid minute") if minute > MAX_MINUTE
      
      is_am = meridiem.upcase == 'AM'
      
      # Convert hour to 24 hour format
      hour =  0 if (hour == MAX_HOUR && is_am) # 12 AM
      hour += MAX_HOUR if (hour != MAX_HOUR && !is_am) # Afternoon, not 12 PM

      # Calculate the total
      total_minutes = (hour * MINUTES_PER_HOUR + minute)
      # Package result
      result = {:total_minutes => total_minutes, :hour_length => hour_length, :meridiem => meridiem}
      }
    return result
  end
  
  # Convert an integer representing the minutes in the day
  # to a string like '{H}H:MM {A|P}M'
  # * The number of hour digits is the same as the input if possible
  # * The case of the meridium is the same as the input
  # [ts_minutes] A hash containing:
  # [:total_minutes] The minutes to be converted
  # [:hour_length] The number of digits to format the hour
  # [:meridiem] The pattern of upper/lower case letters to use for formatting the meridiem
  def self.to_string(ts_minutes)
    minutes = ts_minutes[:total_minutes]
    # Reduce to a 24 hour period
    minutes = minutes % MINUTES_PER_DAY
    # Total hours
    hours = minutes / MINUTES_PER_HOUR
    # Adjusted hours, 0 - 12
    hr = hours % MAX_HOUR
    hr = 12 if hr == 0
    # Remaining minutes
    min = minutes % MINUTES_PER_HOUR
    
    # Format preparation
    hour_format = (ts_minutes[:hour_length] == 1) ? "%d" : "%02d"
    # AM/PM
    am_pm = hours >= MAX_HOUR ? 'PM' : 'AM'
    am_pm = case_like(ts_minutes[:meridiem], am_pm)
    result = "#{hour_format % hr}:#{"%02d" % min} #{am_pm}"
    return result
  end

end # SimpleTime