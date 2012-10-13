class Log

  #def initialize(logLevel)
  @@level = 1
  #end

  def Log::error(msg)
    $stderr.puts "\nERROR: #{msg}"
    exit 1
  end

  def Log::warn(msg)
    $stderr.puts "\nWARNING: #{msg}" if @@level > 0
  end

  def Log::debug(msg)
    puts msg if @@level > 1
  end

end


