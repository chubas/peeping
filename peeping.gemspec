# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{peeping}
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ruben Medellin"]
  s.date = %q{2009-07-12}
  s.description = %q{      Add, remove and manage hooks for class, instance and singleton method calls.
      Intended to be not a full Aspect Oriented Programming framework, but a lightweight
      simpler one.
}
  s.email = %q{ruben.medellin.c@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.markdown"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.markdown",
     "Rakefile",
     "VERSION",
     "lib/peeping.rb",
     "lib/peeping/exceptions.rb",
     "lib/peeping/hook.rb",
     "lib/peeping/peeping.rb",
     "lib/peeping/util.rb",
     "spec/helpers/test_helpers.rb",
     "spec/hook_methods_spec.rb",
     "spec/hooked_behavior_spec.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/chubas/peeping}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.requirements = ["none"]
  s.rubygems_version = %q{1.3.2}
  s.summary = %q{Lightweight AOP framework for managing method hooks}
  s.test_files = [
    "spec/hooked_behavior_spec.rb",
     "spec/hook_methods_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
