require_relative 'client'
require_relative 'project'
require 'fileutils'
class Deployer
  attr_accessor :project_path
  attr_accessor :account
  attr_accessor :config
  attr_accessor :project
  attr_accessor :lambda
  attr_accessor :artifact
  attr_accessor :environments
  attr_accessor :deploy_all

  def initialize(deploy_all, project_path, account, artifact=nil, lambda=nil)
    @deploy_all = deploy_all
    @project_path  = project_path
    @account = account
    @project = Project.new("#{project_path}")
    @config = set_config
    @artifact =  artifact
    @lambda =  lambda
  end

  def set_config
    @project.config
  end

  def get_deployable_lambdas(lambda_env_map)

    if artifact
      lambda_env_map.each do |env, lambdas|
        lambdas.each do |lambda_name, properties|
          lambdas.delete(lambda_name) unless properties['artifact_name'] == artifact
        end
      end
    end

    if lambda
      lambda_env_map.each do |env, lambdas|
        lambdas.each do |lambda_name, properties|
          lambdas.delete(lambda_name) unless lambda_name == lambda
        end
      end
    end
    lambda_env_map
  end

  def deploy(environments)
    account_env_map = project.account_env_map[account]
    env_region_map = project.env_region_map
    #Filter by account as the primary owner of envs
    lambda_env_map = project.get_lambdas
    unless deploy_all
      lambda_env_map = diff_projects(lambda_env_map)
      if lambda_env_map.empty?
        puts "No lambdas have been changed, skipping deploy"
        return
      end
    end
    lambda_env_map = get_deployable_lambdas(lambda_env_map)
    environments ||= project.environments
    account_env_map.each do |env|
      #IF users has specified environments, skip if the environment is not a user specified one
      next unless !environments.nil? && environments.include?(env) && !lambda_env_map[env].nil?
      lambda_env_map[env].each do |lambda_name, properties|
        client = Client.new(env_region_map[env])

        s3_bucket = get_s3_bucket(properties, env)
        s3_key = construct_s3_key(properties, env)

        puts "ENV: #{env}"
        puts "Lambda Name: #{lambda_name}"
        puts "S3 Bucket: #{s3_bucket}"
        puts "S3 Key:  #{s3_key}"
        client.update_function_code(lambda_name,s3_bucket,s3_key)
      end
      archive_project(env)
    end
  end


  def get_s3_bucket(properties, env)
    if properties['s3_bucket']
      return properties['s3_bucket']
    else
      return config['environments'][env]['s3_bucket']
    end

  end

  def construct_s3_key(properties, env)
    if properties['s3_key']
      return properties['s3_key']
    else
      return "#{config['environments'][env]['base_path']}/#{properties['artifact_name']}-#{properties['version']}.#{properties['extension']}"
    end
  end

  def archive_project(environment)
    FileUtils.mkpath("#{project_path}/.history/")
    FileUtils.copy_entry("#{project_path}/config","#{project_path}/.history/config")
    FileUtils.copy_entry("#{project_path}/environments/#{environment}.yaml","#{project_path}/.history/environments/#{environment}.yaml")
  end

  def parse_archive
    archived_project = Project.new("#{project_path}/.history/")
    archived_project.get_lambdas
  end

  def diff_projects(new_project)
    historic = parse_archive
    historic.each do |environment, lambdas|
      lambdas.each do |lambda, configs|
        next if new_project[environment][lambda].nil?
        if new_project[environment][lambda].has_key?('sha1')
          if configs.has_key?('sha1')  && (configs['sha1'] == new_project[environment][lambda]['sha1'])
            new_project[environment].delete(lambda)
          end
        elsif new_project[environment][lambda].eql?(configs)
          new_project[environment].delete(lambda)
        end
      end
      #Delete empty environments as no lambdas changed so they all removed from bing deployable
      new_project.delete(environment) if new_project[environment].empty?
    end
    new_project
  end
end

