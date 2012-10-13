#!/usr/bin/env ruby -w
# encoding: UTF-8
#
# Focus Inspector - The focus inspection and lens calibration software.
#
# Copyright (c) 2012 by Chris Schlaeger <chris@linux.com>
#
# This program is Open Source software; you can redistribute it and/or modify
# it under the terms of MIT license as shipped with this software.

class AppConfig

  attr_reader :imageFile, :command, :viewer

  def initialize(args)
    @imageFile = nil
    @command = nil
    @viewer = 'gwenview'

    version = IO.read(File.expand_path(File.dirname(__FILE__) +
                                       "/../../VERSION")).strip

    opts = OptionParser.new
    opts.banner = <<"EOT"
Focus Inspector v#{version}  (c) Copyright 2012 by Chris Schlaeger

Usage: focusinspector [options] <command> <ImageFile>
EOT

    opts.on('--viewer <viewer>', 'Image viewer to use') do |v|
      @viewer = v
    end

    opts.on_tail('-h', '--help', 'Show this message') do
      puts opts
    end

    opts.separator ""
    opts.separator <<"EOT"
Supported commands are:
  show    : Show image with focus points overlay
  measure : Measure the sharpness of a photo of the test chart
  list    : List some focusing information of the image

EOT

    opts.order!
    @command = ARGV[0]
    unless @command
      Log.error('Command is missing')
      puts opts
    end
    unless %w( show measure list ).include?(command)
      Log.error("Unknown command #{@command}")
      puts opts
    end

    @imageFile = ARGV[1]
    unless @imageFile
      Log.error('Image file name missing.')
      puts opts
    end

    unless File.exists?(@imageFile)
      Log.error("Cannot find image file #{@imageFile}")
    end
  end

end


