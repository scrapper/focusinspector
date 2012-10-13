#!/usr/bin/env ruby -w
# encoding: UTF-8
#
# Focus Inspector - The focus inspection and lens calibration software.
#
# Copyright (c) 2012 by Chris Schlaeger <chris@linux.com>
#
# This program is Open Source software; you can redistribute it and/or modify
# it under the terms of MIT license as shipped with this software.

class Camera

  def initialize(imageFile)
    @imageFile = imageFile
    @cameras = {
                 'NIKON D300' =>
                 begin
                   h = {}
                   xSkip = 0.0676
                   ySkip = 0.095
                   # Rows A to E.
                   (-2).upto(2) do |row|
                     # Rows A and E have only 9 points, the others have 11.
                     cols = row.abs == 2 ? 4 : 5
                     (-cols).upto(cols) do |col|
                     h["#{(?A.ord + row + 2).chr}#{col + cols + 1}"] =
                         [ 0.5 + col * xSkip, 0.5 + row * ySkip ]
                     end
                   end
                   h['C6 (Center)'] = h['C6']
                   h
                 end,
                 'NIKON D5100' =>
                 begin
                   x = [ 0.225, 0.330, 0.5 ]
                   y = [ 0.295, 0.385, 0.5 ]
                   x[3] = x[2] + (x[2] - x[1])
                   x[4] = x[2] + (x[2] - x[0])
                   y[3] = y[2] + (y[2] - y[1])
                   y[4] = y[2] + (y[2] - y[0])
                   {
                     'Far Left'    => [ x[0], y[2] ],
                     'Upper-left'  => [ x[1], y[1] ],
                     'Mid-left'    => [ x[1], y[2] ],
                     'Lower-left'  => [ x[1], y[3] ],
                     'Top'         => [ x[2], y[0] ],
                     'Center'      => [ x[2], y[2] ],
                     'Bottom'      => [ x[2], y[4] ],
                     'Upper-right' => [ x[3], y[1] ],
                     'Mid-right'   => [ x[3], y[2] ],
                     'Lower-right' => [ x[3], y[3] ],
                     'Far Right'   => [ x[4], y[2] ]
                   }
                 end,
                 'NIKON D800' =>
                 begin
                   h = {}
                   # Rows A to E.
                   (-2).upto(2) do |row|
                     # Rows A and E have only 9 points, the others have 11.
                     cols = row.abs == 2 ? 4 : 5
                     (-cols).upto(cols) do |col|
                       # The 3 center columns have a wider x and y spread.
                       if col.abs <= 1
                         xSkip = 0.053
                         xOff = 0.0
                         ySkip = 0.075
                       else
                         xSkip = 0.048
                         xOff = 0.011 * (col < 0 ? -1 : 1)
                         ySkip = 0.0659
                       end
                       h["#{(?A.ord + row + 2).chr}#{col + cols + 1}"] =
                         [ 0.5 + xOff + col * xSkip, 0.5 + row * ySkip ]
                     end
                   end
                   h['C6 (Center)'] = h['C6']
                   h
                 end
               }
    # Add some aliases for similar cameras. Just a guess right now.
    @cameras['NIKON D300S'] = @cameras['NIKON D300']
    @cameras['NIKON D800E'] = @cameras['NIKON D800']

    unless (@exif = MiniExiftool.new(@imageFile))
      Log.error("Image file #{imageFile} has no EXIF information")
    end
    unless (modelName = @exif['Model'])
      Log.error("No camera model name found in image file #{imageFile}")
    end
    unless (@focusPoints = @cameras[modelName])
      Log.error("Camera #{modelName} is not supported.")
    end
    @width = @exif['ImageWidth'].to_i
    @height = @exif['ImageHeight'].to_i
    @cx = @width / 2
    @cy = @height / 2
  end

  def focusAreaSize
    if (afW = @exif['AFAreaWidth']) && (afH = @exif['AFAreaHeight'])
      [ afW, afH ]
    else
      # We currently use a 27th of the screen width and height. This might have
      # to be made camera specific.
      [ @width / 27, @height / 27 ]
    end
  end

  def orientation
    @exif['Orientation'] || "Horizontal (normal)"
  end

  def contrastDetectAF?
    @exif['ContrastDetectAF'] == 'On'
  end

  def focusPoint
    @exif['Primary_AF_Point']
  end

  def focusFineTune
    @exif['AFFineTuneAdj']
  end

  def printDetails
    puts "Focus Mode:              #{@exif['FocusMode']}"
    puts "Contrast Detection:      #{@exif['ContrastDetectAF']}"
    puts "Phase Detection:         #{@exif['PhaseDetectAF']}"
    puts "AF Fine Tune:            #{@exif['AFFineTune']}"
    puts "AF Fine Tune Adjustment: #{@exif['AFFineTuneAdj']}"
    puts "Focus Distance:          #{@exif['FocusDistance']}"
    puts "Depth Of Field:          #{@exif['DOF']}"
    puts "Hyperfocal Distance:     #{@exif['HyperfocalDistance']}"
  end

  def primaryAutoFocusPoint
    if @exif['ContrastDetectAF'] != 'On'
      if (primaryAFP = @exif['Primary_AF_Point']) == "(none)" or primaryAFP.nil?
        Log.error("Image has no primary focus point information")
      end

      unless (coords = fpCoords(primaryAFP))
        Log.error("Unknown focus point #{primaryAFP}")
      end
      return coords
    else
      unless (x = @exif['AFAreaXPosition'])
        Log.error('Contrast detect focus X position not found')
      end
      x = x.to_i
      unless (y = @exif['AFAreaYPosition'])
        Log.error('Contrast detect focus Y position not found')
      end
      y = y.to_i

      return [ x, y ]
    end
  end

  def activeFocusPoints
    return [] if @exif['ContrastDetectAF'] == 'On'

    if (fps = @exif['AFPointsUsed']) == "(none)" or fps.nil?
      Log.error("Image has no focus point information")
    end

    allFPs = @focusPoints.keys.join(',')

    coords = []
    fps.split(',').each do |fp|
      unless (xy = fpCoords(fp))
        Log.error("Unknown focus point #{fp}")
      end
      coords << xy
    end
    coords
  end

  def inactiveFocusPoints
    return [] if @exif['ContrastDetectAF'] == 'On'

    if (fps = @exif['AFPointsUsed']) == "(none)" or fps.nil?
      Log.error("Image has no focus point information")
    end
    fps = fps.split(',')

    allFPs = @focusPoints.keys

    coords = []
    (allFPs - fps).each do |fp|
      coords << fpCoords(fp)
    end
    coords
  end

  private

  def fpCoords(tag)
    x, y = @focusPoints[tag]
    unless x && y
      Log.error("Unknown focus point #{tag} found in image file")
    end
    [ (x * @width).to_i, (y * @height).to_i ]
  end

end


