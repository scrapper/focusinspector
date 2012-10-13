class AppConfig

  attr_reader :imageFile, :details, :sharpness, :view

  def initialize(args)
    @imageFile = nil
    @details = false
    @sharpness = false
    @view = false

    version = IO.read(File.expand_path(File.dirname(__FILE__) +
                                       "/../../VERSION")).strip

    opts = OptionParser.new
    opts.banner = "LensTuner v#{version}  " +
                  "(c) Copyright 2012 by Chris Schlaeger\n\n" +
                  "Usage: lenstuner [options] <ImageFile>"

    opts.on('-d', '--details', 'Show auto focus details') do
      @details = true
    end

    opts.on('-s', '--sharpness', 'Compute the sharpness around the ' +
                                 'focus point') do
      @sharpness = true
    end
    opts.on('-f', '--focuspoints', 'Display image with focus points') do
      @view = true
    end

    opts.on_tail('-h', '--help', 'Show this message') do
      puts opts
    end

    @imageFile = opts.parse(args).first
    unless @imageFile
      Log.error('Image file name missing.')
      puts opts
    end

    unless File.exists?(@imageFile)
      Log.error("Cannot find image file #{@imageFile}")
    end
  end

end


