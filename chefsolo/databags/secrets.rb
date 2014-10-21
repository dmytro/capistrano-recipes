# -*- coding: utf-8 -*-
#
# @author Dmytro Kovalov, dmytro.kovalov@gmail.com
#
namespace :chefsolo do
  namespace :databag do

    desc <<-EOF
Installs secret databags from S3.

Databags are copied to chef/data_bags directory. Recipe does not
overwrite existing file.

Configuration:

- To enable recipe set :use_s3_secrets to true:

   set :use_s3_secrets, true


- Set path to access data_bags on S3:

   set :s3_secret_databag_path, "/secrets/data_bags/"

- Set S3 region:

   set :s3_region, "ap-northeast"

S3 credentials
--------------

To use this recipe create file `config/secrets/s3.yml` with follwing
content:

    ---
    access_key_id: 'KEYID'
    secret_access_key: 'SECRET_ACCESS_KEY'


Source File #{path_to __FILE__}

EOF
    task :secrets do

      keys = YAML.load_file("config/secrets/s3.yml")

      conn = AWS::S3::Base.establish_connection!(
        :access_key_id => keys["access_key_id"],
        :secret_access_key => keys["secret_access_key"]
      )
      AWS::S3::DEFAULT_HOST.replace "s3-#{s3_region}-1.amazonaws.com"

      bucket = AWS::S3::Bucket.find(s3_secret_databag_path.split("/")[1])

      bucket.each do |file|

        path = file.path
        next unless path.slice! s3_secret_databag_path
        dir = FileUtils.mkdir_p("#{local_chef_cache_dir}/#{File.dirname(path)}")

        File.open("#{local_chef_cache_dir}/#{path}", "w") do |f|
          f.write file.value
          f.close
        end
      end
    end
  end                           # namespace databag
end                             # namespace chefsolo
