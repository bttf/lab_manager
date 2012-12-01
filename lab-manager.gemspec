Gem::Specification.new do |s|
  s.name        = 'lab-manager'
  s.version     = '1.0.12'
  s.date        = '2012-11-05'
  s.summary     = "Client for VMWare Lab Manager"
  s.description = "Access information about and manipulate your Lab Manager configurations."
  s.authors     = ["Ed Sumerfield"]
  s.email       = 'esumerfield@ipcoop.com'
  s.executables = Dir["bin/*.sh"].collect { |file| File.basename file }
  s.files       = Dir['lib/**/*.rb']

  s.add_runtime_dependency("mumboe-soap4r")

  s.add_development_dependency("rspec", [">= 0"])
end
