require 'aws-sdk'
class Client
  attr_accessor :client
  def initialize(aws_region)
    @client = Aws::Lambda::Client.new(region: aws_region)
  end

  def update_function_code(function_name, s3_bucket, s3_key)
    response = client.update_function_code({function_name: function_name, s3_bucket: s3_bucket, s3_key: s3_key})
    puts "Updated: #{response.function_name}"
  end
end