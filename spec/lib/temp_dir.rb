def new_temp_dir
  #Get a new temporary directory
  temp = Tempfile.new SecureRandom.hex
  path = temp.path
  temp.close!

  FileUtils.mkdir_p path
  return path
end

def dirs
  Dir["**/*"].select{|e| File.directory?(e)}
end

def files
  Dir["{*,.*}"].select{|e| File.file?(e)} #Match dotfiles and normal files
end
