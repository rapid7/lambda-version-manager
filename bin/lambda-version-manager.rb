#!/usr/bin/env ruby
#
require 'thor'
require 'yaml'
require 'pp'
require_relative '../lib/project'
require_relative '../lib/deployer'
class GeneratorCLI < ::Thor

  desc 'deploy', 'Deploy the updated lambda versions'
  option 'project_path', banner: 'PROJECT_PATH', type: :string, desc: 'Path to the lambda version mappings project'
  option 'environments', banner: 'ENVIRONMENT', type: :array, desc: 'Deploy lambdas in this environment'
  option 'artifact', banner: 'ARTIFACT', type: :string, desc: 'Deploy lambdas that use this artifact'
  option 'lambda', banner: 'LAMBDA', type: :string, desc: 'Deploy lambdas with this name'
  option 'account', banner: 'ACCOUNT', type: :string, desc: 'Account to deploy to', :required => true
  option 'version_map_file', banner: 'VERSION_MAP_FILE', type: :string, desc: 'A java properties file mapping artifacts to update to version'

  def deploy
    opts = parse_options(options)
    if opts['version_map_file']
      #for each x=y pair we need to call
      File.readlines(options['version_map_file']).each do |line|
        array = line.split("=")
        deployer = Deployer.new(opts['project_path'], opts['account'], array[0].strip)
        deployer.deploy(opts['environments'])
      end
    else
      deployer = Deployer.new(opts['project_path'], opts['account'], opts['artifact'], opts['lambda'])
      deployer.deploy(opts['environments'])
    end
  end

  desc 'update_project', 'Update the versions'
  option 'project_path', banner: 'PROJECT_PATH', type: :string, desc: 'Path to the lambda version mappings project'
  option 'artifact', banner: 'ARTIFACT', type: :string, desc: 'Deploy lambdas that use this artifact'
  option 'version', banner: 'VERSION', type: :string, desc: 'Version of the new artifact'
  option 'version_map_file', banner: 'VERSION_MAP_FILE', type: :string, desc: 'A java properties file mapping artifacts to update to version'
  option 'accounts', banner: 'ACCOUNT', type: :array, desc: 'Account to deploy to', :required => true

  def update_project
    opts = parse_options(options)
    project = Project.new(opts['project_path'])
    lambda_env_map = project.get_lambdas
    account_env_map =  project.account_env_map

    supportd_envs = []
    opts['accounts'].each do | account|
      supportd_envs += account_env_map[account]
    end

    lambda_env_map.each do |env, lamdas|
      unless supportd_envs.include?(env)
        lambda_env_map.delete(env)
      end
    end


    if opts['version_map_file']
      #for each artifact=version pair we need to call
      File.readlines(opts['version_map_file']).each do |line|
        array = line.split("=")
        updated_files = project.update_by_artifact(lambda_env_map, array[0].strip, array[1].strip)
        lambda_env_map = updated_files
      end
    else
      lambda_env_map = project.update_by_artifact(lambda_env_map, opts['artifact'], opts['version'])
    end
    project.write_new_files(lambda_env_map)
  end

  no_commands do
    def parse_options(options)
      unless options['version_map_file'] || (options['version'] && (options['lambda'] || options['artifact']))
        raise 'Either a file must be specified or a version and lambda or artifact.'
      end
      #add input validation, either a file must be specified or a version and lambda or artifact.
      opts = options.dup
      opts
    end
  end
end

GeneratorCLI.start(ARGV)