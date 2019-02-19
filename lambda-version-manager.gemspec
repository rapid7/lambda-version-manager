Gem::Specification.new do |s|
  s.name        = 'lambda-version-manager'
  s.version     = '0.0.1'
  s.date        = '2019-02-19'
  s.summary     = "Lambda version manager"
  s.description = "Updates aws lambda versions to match a yaml property file"
  s.authors     = ["Bryan Call"]
  s.email       = 'bcall@rapid7.com'
  s.files       =  Dir.glob("{bin,lib}/**/*") + %w(README.md)
  s.homepage    =
    'http://rubygems.org/gems/lambda-version-manager'
  s.license       = 'MIT'
  s.executables = %w(lambda-version-manager)
  s.bindir = 'bin'

  s.add_dependency 'aws-sdk', '~> 1.0.0.rc2'
  s.add_dependency 'thor'
  S.add_dependency 'thor-scmversion'
end