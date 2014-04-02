# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "hash-tree"
  s.version     = "0.0.2"
  s.authors     = ["Sebastien Rosa"]
  s.email       = ["sebastien@demarque.com"]
  s.extra_rdoc_files = ["LICENSE", "README.md"]
  s.licenses    = ["MIT"]
  s.homepage    = "https://github.com/demarque/hash-tree"
  s.summary     = "Manage nested hash"
  s.description = "HashTree help you to work with nested hashes and arrays."

  s.rubyforge_project = "hash-tree"

  s.files         = Dir.glob('{lib,spec}/**/*') + %w(LICENSE README.md Rakefile Gemfile)
  s.require_paths = ["lib"]

  s.add_dependency("json", [">= 1.5.0"])
  s.add_dependency("ya2yaml", [">= 0.30"])
  s.add_dependency("nori", ["~> 1.1.0"])

  s.add_development_dependency('rake', ['>= 0.8.7'])
  s.add_development_dependency('rspec', ['>= 2.0'])
  s.add_development_dependency('rspec-aspic', ['>= 0.0.2'])
end
