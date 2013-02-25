Gem::Specification.new do |s|
  s.name              = "arnold"
  s.version           = '0.0.1'
  s.date              = "2013-02-22"
  s.summary           = "A simplistic self service provisioner and Puppet classifier."
  s.homepage          = "http://github.com/binford2k/arnold"
  s.email             = "binford2k@gmail.com"
  s.authors           = ["Ben Ford"]
  s.has_rdoc          = false
  s.require_path      = "lib"
  s.executables       = %w( arnold )
  s.files             = %w( README.md LICENSE )
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("bin/**/*")
  s.files            += Dir.glob("doc/**/*")
  s.files            += Dir.glob("views/**/*")
  s.files            += Dir.glob("public/**/*")
  s.add_dependency      "sinatra", "~> 1.3"
  s.description       = <<-desc
  This is the start of a Puppet provisioning system.

  It provides a graphical web service, a JSON rest API and command line interface
  that will manage Hiera YAML files and a few functions to read them and apply
  classes and parameters to a node. It works like a lightweight External
  Node Classifier.

  It also provides provisioning functionality to spin up new instances after
  classifying them. It currently has a backend for Cloud Provisioner and will
  shortly have a VMWare plugin to spin up new instances for Razor to provision.
  New backend plugins are quite easy to create. Documentation forthcoming.
  desc
end