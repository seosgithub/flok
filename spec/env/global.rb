bin_path = File.join(File.dirname(__FILE__), "../../bin/")
$flok_bin_path = File.join(File.dirname(__FILE__), "../../bin/flok")
ENV['PATH'] = "#{bin_path}:#{ENV['PATH']}"
