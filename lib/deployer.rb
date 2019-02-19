require_relative 'client'
require_relative 'project'
class Deployer
  attr_accessor :project_path
  attr_accessor :account
  attr_accessor :config
  attr_accessor :project
  attr_accessor :lambda
  attr_accessor :artifact

  def initialize(project_path, account, artifact, lambda)
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
    lambda_env_map = get_deployable_lambdas(lambda_env_map)
    account_env_map.each do |env|
      #IF users has specified environments, skip if the environment is not a user specified one
      next if !environments.nil? && environments.include?(env)
      lambda_env_map[env].each do |lambda_name, properties|
        client = Client.new(env_region_map[env])

        s3_bucket = get_s3_bucket(properties, env)
        s3_key = construct_s3_key(properties, env)

        puts "ENV: #{env}"
        puts "Lambda Name: #{lambda_name}"
        puts "S3 Bucket: #{s3_bucket}"
        puts "S3 Key:  #{s3_key}"
        #client.update_function_code(lambda_name,s3_bucket,s3_key)
      end
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
      return "#{config['environments'][env]['base_path']}/#{properties['artifact_name']}#{properties['artifact_name']}-#{properties['version']}.#{properties['extension']}"
    end
  end
end

