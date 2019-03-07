## **Getting Started**

#### Creating your version management project:
##### Step 1: Creating your config.yml
1. Create your top level directory for your project.

    `mkdir example-lambdas`

2. Create a config directory and inside a config.yml file.

```sh
cd example-lambdas/
mkdir config
cd config
touch config.yml
```

The config.yml will define essential configurations that the lambda version manager needs update the lambdas with the correct s3 key location.
In the config.yml file we need three keys set to explain our project to the generator.

1. The `environments` key. This key will define a array of the environments that we are setting properties for. Environments must be unique.
2. Under each `environment` value the following values must be defined. 
    * `region` The aws region for the environment. This is used to making aws sdk calls. 
    * `account` The aws account that this environment lives in. This can be used to limits deployments for example between staging and prod accounts.
    * `s3_bucket` The s3 bucket that lambda artifacts are uploaded too.
    * `base_path` The path in the s3 bucket above to the lambda artifacts. 
    
Here is a example config.yml
```yaml
environments:
  us-east-1: #prod
    region: us-east-1
    account: "123456789101"
    s3_bucket: "lambdastorage.us-east-1.prod.myspecials3domain.com"
    base_path: "lambdas"
  eu-central-1:
    region: eu-central-1
    account: "123456789101"
    s3_bucket: "lambdastorage.prod.eu-central-1.myspecials3domain.com"
    base_path: "lambdas"   
  staging: #staging
    region: us-east-1
    account: "101987654321"
    s3_bucket: "lambdastorage.staging.us-east-1.mys3domain.com"
    base_path: "lambdas"
```
    
##### Step 2: Creating your environments
The environments folder will contain the environments which will contain the managed lambdas.
###### Top level globals
1. Create a environments folder
```sh
cd example-lambdas/
mkdir environments
```
2. Make a yaml files with the same names as the environment keys under your environment block in the `config.yml`.
```sh
cd example-lambdas/environments
touch us-east-1.yaml
touch eu-central-1.yaml
touch staging.yaml
```

###### Managing Lambdas in an Environment
1. To manage a lambda in a give environment it must be defined in the given environment file by its function name. 
2. The top level key must be the function(lambda) name.
3. Below the function name define the following keys
    * `artifact_name` The artifact name. This name must match the name of the built artifact the lambda uses.
    * `version` The version of the artifact. 
    * `extension` The extension of the artifact.
4. Optional keys to define
    * `sha1` The sha1 sum of the artifact. This useful if you repeatedly build the same version and therefore need to generate a diff to trigger an update to the lambda.
    * `s3_bucket` An alternate s3 bucket to use as a artifact source over the one specified in the config. 
    * `s3_key` Specifying this will tell the version manager to use this as the exact path to the artifact in s3. This overrides the derived path from the `artifact_name`, `version`, and `extension` values.
5. An example of an environment file is below
```yaml
user_registration: #lambda name
  artifact_name: user-registration #Name of artifact produced by the build and uploaded to s3
  version: 1.0.41-SNAPSHOT
  extension: jar
expired_document_cleanup:
  artifact_name: expired-document-cleanup
  version: 1.0.7
  extension: jar
  sha1: klf90849u5hkwhfp9op2ojrfy3rubmwlehr
```
##### Using the CLI to deploy a lambda
The bin directory contains the lambda-version-manager cli. An example of running the cli is below. The `project_path` argument specifies the path to the lambda management whose creation was defined above. This will deploy all the lambdas in the us-east-1 environment in the supplied account that have changed since the last deploy. 
```sh
./lambda-version-manager deploy --project_path ~/example-lambdas/ --environments us-east-1 --account 123456789101```
```
##### Using the CLI to update a lambdas configuration
The command below will update the yaml configuration block for the lambdas that use the user-registration artifact to the supplied version in the give accounts.
```sh
./lambda-version-manager update_project --project_path ~/example-lambdas/ --artifact user-registration --version 1.0.42-SNAPSHOT --accounts 123456789101
```