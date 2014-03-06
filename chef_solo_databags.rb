
require 'json'

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

          # :node databag
          # ----------------------
          File.open("#{node_dir}/#{server}.json", "w") do |f|
            f.print(({
                       id:                   server.host.gsub(/\./,'_'),
                       name:                 server.host,
                       role:                 role_names_for_host(server), # 2 entires for roles `role` used by Munin, `roles` by Nagios
                       roles:                role_names_for_host(server), 
                       fqdn:                 server.options[:hostname] || server.host, 
                       ipaddress:            server.host,
                       os:                   server.options[:os] || 'linux', # TODO get real os of :node
                       chef_environment:     fetch(:stage)
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
          stage = fetch(:stage)
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
