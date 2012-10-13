#!/usr/bin/env ruby -w
# encoding: UTF-8
#
# Focus Inspector - The focus inspection and lens calibration software.
#
# Copyright (c) 2012 by Chris Schlaeger <chris@linux.com>
#
# This program is Open Source software; you can redistribute it and/or modify
# it under the terms of MIT license as shipped with this software.

require 'focusinspector/Log'
require 'focusinspector/AppConfig'
require 'focusinspector/Camera'
require 'focusinspector/SharpnessMeter'
require 'focusinspector/ImageMarker'
require 'focusinspector/ImageViewer'

class FocusInspector

  def initialize(args)
    @config = AppConfig.new(args)

    @imageFile = @config.imageFile
    # Conver the raw file to jpg if we have one.
    convertRaw

    focusInfo = Camera.new(@imageFile)
    x, y = focusInfo.primaryAutoFocusPoint

    case @config.command
    when 'list'
      focusInfo.printDetails
    when 'measure'
      sm = SharpnessMeter.new(@jpgFile)
      puts "Sharpness:  %.2f%%  (%s)" % [ (sm.measure(x, y) * 100.0),
           focusInfo.contrastDetectAF? ? 'Contrast Detection AF' :
           "FP: #{focusInfo.focusPoint}  AFFT: #{focusInfo.focusFineTune}" ]
    when 'show'
      im = ImageMarker.new(@jpgFile, *focusInfo.focusAreaSize, @config.viewer)
      im.mark(x, y, 'red', true)

      activeFPxy = focusInfo.activeFocusPoints
      inactiveFPxy = focusInfo.inactiveFocusPoints

      activeFPxy.each { |xy| im.mark(*xy, 'red') }
      inactiveFPxy.each { |xy| im.mark(*xy, 'grey') }

      im.show(focusInfo.orientation)
    end
  end

  def convertRaw
    if @imageFile[-4..-1] == '.NEF' || @imageFile[-4..-1] == '.nef'
      @tmpJPGfile = Tempfile.new('lenstuner-jpg')
      @tmpJPGfile.close
      @jpgFile = @tmpJPGfile.path
      command = "dcraw -c -e #{@imageFile} > #{@jpgFile}"
      unless system(command)
        Log.error("Cannot execute '#{command}'")
      end
    else
      @jpgFile = @imageFile
    end
  end

end

