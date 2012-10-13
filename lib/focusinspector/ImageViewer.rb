
class ImageViewer

  def initialize(image)
    # Write the marked version of the original image to a temporary file.
    file = Tempfile.new('lenstuner')
    image.write('jpeg:' + file.path)
    file.close
    # Start 'gwenview' to display the marked image.
    system("gwenview #{file.path} 2> /dev/null")
  end

end

