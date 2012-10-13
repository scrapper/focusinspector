#!/usr/bin/env ruby -w
# encoding: UTF-8
#
# Focus Inspector - The focus inspection and lens calibration software.
#
# Copyright (c) 2012 by Chris Schlaeger <chris@linux.com>
#
# This program is Open Source software; you can redistribute it and/or modify
# it under the terms of MIT license as shipped with this software.

class ImageMarker

  def initialize(imageFile, w, h, viewer)
    begin
      @image = Magick::Image.read(imageFile).first
      # The size of the auto focus area.
      @w = w
      @h = h
    rescue
      Log.error("Cannot open image file #{imageFile}")
    end
    @viewer = viewer
  end

  def mark(x, y, color, bold = false)
    painter = Magick::Draw.new
    painter.fill_opacity(0.0)
    painter.stroke(color)
    painter.stroke_width = bold ? 13 : 9
    painter.rectangle(x - @w / 2, y - @h / 2, x + @w / 2, y + @h / 2)
    painter.draw(@image)
  end

  def show(orientation)
    # Since we have created a new image, the orientation of the original got
    # lost. We simply rotate the image to match the original orientation.
    case orientation
    when 'Rotate 90 CW'
      @image.rotate!(90)
    when 'Rotate 270 CW'
      @image.rotate!(270)
    end

    ImageViewer.new(@image, @viewer)
  end

end

