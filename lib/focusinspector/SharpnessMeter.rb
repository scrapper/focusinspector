
class SharpnessMeter

  def initialize(imageFile)
    @imageFile = imageFile
    @minSquareSize = 100
  end

  def measure(x, y)
    image = Magick::Image.read(@imageFile).first

    x, y, sqSize = findBlackSquare(image, x, y)
    crop = cropQuadrants(image, x, y)
    #ImageViewer.new(image)
    colorHistogram = crop.color_histogram
    bwHistogram = convertHistToBW(colorHistogram)
    calcSharpness(bwHistogram, crop)
  end

  private

  def color(image, x, y, radius = 2)
    blackCount = 0
    whiteCount = 0
    greyCount = 0
    (-radius).upto(radius) do |xi|
      (-radius).upto(radius) do |yi|
        col = image.pixel_color(x + xi, y + yi)
        val = (col.red + col.green + col.blue) / 3
        if val < 0x6000
          blackCount += 1
        elsif val > 0xA000
          whiteCount += 1
        else
          greyCount += 1
        end
      end
    end
    if blackCount > whiteCount && blackCount > greyCount
      :black
    elsif whiteCount > blackCount && whiteCount > greyCount
      :white
    else
      :grey
    end
  end

  def showMarkedImage(image, x, y, w, h)
    painter = Magick::Draw.new
    painter.opacity(0)
    painter.stroke('red')
    painter.stroke_width =  9
    painter.rectangle(x, y, x + w, y + h)
    painter.draw(image)

    ImageViewer.new(image)
    exit
  end

  def findEdge(image, x, y, dx, dy)
    startCol = color(image, x, y)
    raise 'Starting point must not be grey.' if startCol == :grey

    while (c = color(image, x, y)) == :grey || c == startCol
      if c == startCol
        sx = x
        sy = y
      end
      x += dx
      y += dy

      if x < 0 || x >= image.columns || y < 0 || y >= image.rows
        Log.error("Cannot detect the edge of the square (#{dx}, #{dy}).")
      end
    end
    ex = x
    ey = y

    # The edge is located right in the middle of the grey zone.
    [ sx + (ex - sx) / 2, sy + (ey - sy) / 2 ]
  end

  def findBlackSquare(image, x, y)
    # Find a pixel inside of a black square by moving along a spiral line.
    stepInc = 11
    steps = stepInc
    stepCount = 0
    dir = :right
    while color(image, x, y) != :black
      case dir
      when :right
        x += steps
        dir = :down unless stepCount % 2 == 0
      when :down
        y += steps
        dir = :left unless stepCount % 2 == 0
      when :left
        x -= steps
        dir = :up unless stepCount % 2 == 0
      when :up
        y -= steps
        dir = :right unless stepCount % 2 == 0
      end
      if stepCount < 3
        stepCount += 1
      else
        stepCount = 0
        steps += stepInc
      end
      Log.debug("x: #{x}  y: #{y}")
      if x < 0 || x >= image.columns || y < 0 || y >= image.rows
        Log.error("No black square found.")
      end
    end
    #image.crop!(x - 15, y - 15, 30, 30)
    #ImageViewer.new(image)
    #exit

    blackSqX0 = findEdge(image, x, y, -1, 0)[0]
    blackSqX1 = findEdge(image, x, y, 1, 0)[0]
    blackSqY0 = findEdge(image, x, y, 0, -1)[1]
    blackSqY1 = findEdge(image, x, y, 0, 1)[1]

    # Compute the edge length of the square.
    sqWidth = blackSqX1 - blackSqX0 + 1
    sqHeight = blackSqY1 - blackSqY0 + 1

    Log.debug("Square size is #{sqWidth} x #{sqHeight}")
    if sqWidth < @minSquareSize || sqHeight < @minSquareSize
      Log.error("The size (#{sqWidth} x #{sqHeight}) of the detected " +
                "black square is too small.")
    end

    #showMarkedImage(image, blackSqX0, blackSqY0, sqWidth, sqHeight)

    [ blackSqX0, blackSqY0, (sqWidth + sqHeight) / 2 ]
  end

  def cropQuadrants(image, bx, by)
    probeSize = @minSquareSize
    # Return a probeSize sized rectangle with the top left corner of the
    # black square in the center spot.
    radius = @minSquareSize / 2
    x = bx - radius
    y = by - radius

    #showMarkedImage(image, x, y, probeSize, probeSize)
    unless color(image, x, y, radius) == :black
      Log.error("Top-left quadrant is not black")
    end
    unless color(image, x, y + @minSquareSize, radius) == :white
      Log.error("Bottom-left quadrant is not white")
    end
    unless color(image, x + @minSquareSize, y + @minSquareSize,
                 radius) == :black
      Log.error("Bottom-right quadrant is not black")
    end
    unless color(image, x + @minSquareSize, y, radius) == :white
      Log.error("Top-right quadrant is not white")
    end

    image.crop(x, y, probeSize, probeSize)
  end

  def convertHistToBW(cHist)
    bwHist = Hash.new(0)

    cHist.each do |rgb, val|
      # The color histogram contains the values for 16 bit RGB colors.
      bwHist[(rgb.red + rgb.green + rgb.blue) / 3] += val
    end

    #bwHist.each { |i, v | Log.debug("Color #{i}: #{v}") }
    bwHist
  end

  def findHistogramPeak(hist, black)
    peakIndex = nil
    if black
      sIdx = 0
      eIdx = 0x7FFF
    else
      sIdx = 0x8000
      eIdx = 0xFFFF
    end

    sIdx.upto(eIdx) do |i|
      if peakIndex.nil? || hist[peakIndex] < hist[i]
        peakIndex = i
      end
    end

    peakIndex
  end

  def calcSharpness(bwHist, image)
    peakBlackIndex = findHistogramPeak(bwHist, true)
    peakWhiteIndex = findHistogramPeak(bwHist, false)

    hEdge = 0
    image.columns.times do |c|
      hEdge += edgeSharpness(image, c, 0, 0, 1)
    end
    hEdge /= image.columns

    vEdge = 0
    image.rows.times do |r|
      vEdge += edgeSharpness(image, 0, r, 1, 0)
    end
    vEdge /= image.rows

    maxEdge = peakWhiteIndex - peakBlackIndex

    ((hEdge + vEdge) / 2.0) / maxEdge
   end

   def edgeSharpness(image, x, y, dx, dy)
     biggestDelta = 0
     while (x >= 0 && x < image.columns && y >= 0 && y < image.rows)
       nx = x + dx
       ny = y + dy
       col = image.pixel_color(x, y)
       val1 = (col.red + col.green + col.blue) / 3
       col = image.pixel_color(nx, ny)
       val2 = (col.red + col.green + col.blue) / 3
       delta = (val1 - val2).abs
       biggestDelta = delta if biggestDelta < delta
       x = nx
       y = ny
     end

     biggestDelta
   end

end

