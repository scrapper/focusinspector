#!/usr/bin/env ruby -w
# encoding: UTF-8
#
# Focus Inspector - The focus inspection and lens calibration software.
#
# Copyright (c) 2012 by Chris Schlaeger <chris@linux.com>
#
# This program is Open Source software; you can redistribute it and/or modify
# it under the terms of MIT license as shipped with this software.

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


