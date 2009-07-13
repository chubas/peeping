require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    
    gem.name      = "peeping"
    gem.email     = "ruben.medellin.c@gmail.com"
    gem.summary   = %Q{Lightweight AOP framework for managing method hooks}
    gem.description  = <<-DESCRIPTION
      Add, remove and manage hooks for class, instance and singleton method calls.
      Intended to be not a full Aspect Oriented Programming framework, but a lightweight
      simpler one.
    DESCRIPTION

    gem.homepage  = "http://github.com/chubas/peeping"
    gem.authors   = ["Ruben Medellin"]

    gem.requirements << 'none'
    gem.require_path = 'lib'

    gem.has_rdoc     = true
    gem.test_files   = Dir.glob('spec/*.rb')

  end

rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

task :default => :test
require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION.yml')
    config = YAML.load(File.read('VERSION.yml'))  
    version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
  elsif File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "peeping #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

