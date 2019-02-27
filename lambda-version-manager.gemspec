Gem::Specification.new do |s|
  s.name        = 'lambda-version-manager'
  s.version     = '0.0.13'
  s.date        = '2019-02-19'
  s.summary     = "Lambda version manager"
  s.description = "Updates aws lambda versions to match a yaml property file"
  s.authors     = ["Bryan Call"]
  s.email       = 'bcall@rapid7.com'
  s.files       =  Dir.glob("{bin,lib}/**/*")
  s.homepage    =
    'http://rubygems.org/gems/lambda-version-manager'
  s.license       = 'MIT'
  s.executables = %w(lambda-version-manager)
  s.bindir = 'bin'
  s.add_dependency 'aws-sdk-lambda', '~> 1.0.0.rc8'
  s.add_dependency 'thor'
  s.add_dependency 'thor-scmversion'
end
