class Project
  attr_accessor :config
  attr_accessor :project_path

  def initialize(project_path)
    @config = YAML.load_file("#{project_path}/config/config.yaml")
    @project_path = project_path
  end

  def environments
    config['environments']
  end

  def get_lambdas
    lambdas = {}
    environments.keys.each do |env|
      lambdas[env] = YAML.load_file("#{project_path}/environments/#{env}.yaml")
    end
    lambdas
  end

  def account_env_map
    hash = {}
    config['environments'].each do |env, properties|
      if hash[properties['account']].nil?
        hash[properties['account']] = []
        hash[properties['account']] << env
      else
        hash[properties['account']] << env
      end
    end
    hash
  end

  def env_region_map
    hash = {}
    config['environments'].each do |env, properties|
      if hash[env].nil?
        hash[env] = properties['region']
      else
        raise("An environment cannot map to more than one region ENV: #{env} Region: #{properties['region']}")
      end
    end
    hash
  end


  def write_new_files(lambda_env_map)
    lambda_env_map.each do |env, contents|
      File.write("#{project_path}/environments/#{env}.yaml", contents.to_yaml)
    end
  end

  def update_by_artifact(lambda_env_map, artifact, version)
    #iterate through all lambdas and update the ones with version changes
    lambda_env_map.each do |env, lambda|
      pp env
      pp lambda
      lambda.each do |lambda_name, properties|
        if properties['artifact_name'] == artifact
          properties['version'] = version
        end
      end
    end
    lambda_env_map
  end
end