Gem::Specification.new do |spec|
  spec.name = "gvf"
  spec.version = "0.1.0"
  spec.summary = "gemfile version fixer"
  spec.authors = ["kinduff"]
  spec.license = "MIT"
  spec.homepage = "https://github.com/kinduff/gvf"
  spec.files = Dir["lib/**/*.rb", "exe/*"]
  spec.bindir = "exe"
  spec.executables = ["gvf"]
  spec.require_paths = ["lib"]
end
