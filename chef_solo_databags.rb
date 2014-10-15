# -*- coding: utf-8 -*-

set_default :s3_secret_databag_path, "/secrets/data_bags/"
set_default :s3_region, "ap-northeast"

require 'json'
require "aws/s3"

namespace :chefsolo do
  namespace :databag do

    # @param [String] name name of the databag (directory)
    # @param [Hash] data
    # def write_databag name, data
    # end


    desc <<-DESC
[internal] Build Chef databag from Capistrano configuration.

Expose Capistrano configuration to Chhef as databag. Create and save
data_bag to all remote servers with current Capistrano
configuration. Databag is :capistrano, item :config.

Actuall contents of the databag depends on the configuration, all
Capistrano variables exported as hash.

See also `cap -e configuration_bag`

Source #{path_to __FILE__}
DESC
    task :cap do
      top.configuration_bag
    end

    desc <<-DESC
[internal] Build databag with server roles.

Build databag to send to servers containing all remote server roles an
server options. Databag name is :node, each item name is server
name from capistrano server definitions.

Databag usage
-------------

Databags are used by script (run_role.rb) running on the remote host
by chefsolo:roles task.

Databag format
--------------

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    {
      "id": "10_0_40_252",
      "role": [
        "app",
        "web",
        "admin",
        "logger"
      ],
      "options": {
        "app_type": "admins",
        "hostname": "admin-test"
      },
      "ipaddress": "10.0.40.252",
      "fqdn": "10.0.40.252"
    }
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Source #{path_to __FILE__}
DESC

    task :roles do
      data = { }


      begin
        node_dir = run_locally(%{ mktemp -d /tmp/tempdatabag.XXXX }).chomp
        role_dir = run_locally(%{ mktemp -d /tmp/tempdatabag.XXXX }).chomp
        env_dir  = run_locally(%{ mktemp -d /tmp/tempdatabag.XXXX }).chomp

        roles = { }
        find_servers.each do |server|

          role_names_for_host(server).each do |role|
            roles[role] ||= []
            roles[role] << server
          end

          ip_address = (server.host =~ /(\d+\.){3}\d+/) ? server.host : '127.0.0.1'
          # :node databag
          # ----------------------
          File.open("#{node_dir}/#{server}.json", "w") do |f|
            f.print(({
                       id:                   server.host.gsub(/\./,'_'),
                       name:                server.host,
                       keys: '',
                       # 2 entires for roles `role` used by Munin, `roles` by Nagios
                       role:                 role_names_for_host(server),
                       roles:                role_names_for_host(server),
                       fqdn:                 server.options[:hostname] || server.host,
                       ipaddress:            ip_address,
                       os:                   server.options[:os] || 'linux', # TODO get real os of :node
                       chef_environment:     fetch(:chef_environment),
                       ossec:                {  } #need for search in ossec cookbook
                     }).merge(server.options).to_json)
            f.close
          end
        end

        # :role databag
        # ----------------------
        roles.keys.each do |role|
          File.open("#{role_dir}/#{role}.json", "w") do |f|
            f.print({
                      id:            role,
                      name:          role,
                      hosts:         roles[role].map(&:host)
                      #hostnames:     roles[role].map(&:options)
                    }.to_json)
            f.close
          end

          # :environment databag
          # ----------------------
          stage = fetch(:chef_environment)
          File.open("#{env_dir}/#{stage}.json", "w") do |f|
            f.print({
                      id:    stage,
                      name:  stage
                    }.to_json)
            f.close
          end

        end
        copy_dir node_dir, "#{local_chef_cache_dir}/data_bags/node"
        copy_dir role_dir, "#{local_chef_cache_dir}/data_bags/role"
        copy_dir role_dir, "#{local_chef_cache_dir}/data_bags/roles"
        copy_dir env_dir,  "#{local_chef_cache_dir}/data_bags/environment"
      ensure
       run_locally "rm -rf #{node_dir} #{role_dir} #{env_dir}"
      end
    end

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


desc <<-DESC
[internal] Build databag from Capistrano configuration.

This needs to be top level recipe, variables are not accessible in the
namespaced scope.

Source #{path_to __FILE__}
DESC
task :configuration_bag do
  vars = {}
  @variables.each { |k,v| vars[k] = v unless v.class == Proc }

  dir = "#{local_chef_cache_dir}/data_bags/capistrano"
  FileUtils.mkdir_p dir
  File.open("#{dir}/config.json", "w") do |file|
    file << vars.merge({ "id" => "config"}).to_json
    file.close
  end

end
