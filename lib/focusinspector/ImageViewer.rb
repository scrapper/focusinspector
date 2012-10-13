#!/usr/bin/env ruby -w
# encoding: UTF-8
#
# Focus Inspector - The focus inspection and lens calibration software.
#
# Copyright (c) 2012 by Chris Schlaeger <chris@linux.com>
#
# This program is Open Source software; you can redistribute it and/or modify
# it under the terms of MIT license as shipped with this software.

class ImageViewer

  def initialize(image, viewer)
    # Write the marked version of the original image to a temporary file.
    file = Tempfile.new('lenstuner')
    image.write('jpeg:' + file.path)
    file.close
    # Start viewer to display the marked image.
    command = "#{viewer} #{file.path} 2> /dev/null"
    unless system(command)
      Log.error("Cannot execute '#{command}'")
    end
  end

end

