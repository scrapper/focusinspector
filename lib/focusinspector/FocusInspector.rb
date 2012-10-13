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

    if @config.details
      focusInfo.printDetails
    end

    if @config.sharpness
      sm = SharpnessMeter.new(@jpgFile)
      puts "Sharpness:  %.2f%%  (%s)" % [ (sm.measure(x, y) * 100.0),
           focusInfo.contrastDetectAF? ? 'Contrast Detection AF' :
           "FP: #{focusInfo.focusPoint}  AFFT: #{focusInfo.focusFineTune}" ]
    end

    if @config.view
      im = ImageMarker.new(@jpgFile, *focusInfo.focusAreaSize)
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
      system("dcraw -c -e #{@imageFile} > #{@jpgFile}")
    else
      @jpgFile = @imageFile
    end
  end

end

