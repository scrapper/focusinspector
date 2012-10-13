
class ImageMarker

  def initialize(imageFile, w, h)
    begin
      @image = Magick::Image.read(imageFile).first
      # The size of the auto focus area.
      @w = w
      @h = h
    rescue
      Log.error("Cannot open image file #{imageFile}")
    end
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

    ImageViewer.new(@image)
  end

end

