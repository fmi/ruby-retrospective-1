watch(%r{solutions/(\d+).rb}) do |m|
  system "clear"
  system "rake tasks:#{m[1]}"
end
