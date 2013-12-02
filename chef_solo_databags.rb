
require 'json'

namespace :chefsolo do
  namespace :databag do

    desc <<-DESC
Build Chef databag from Capistrano configuration.

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
Build databag with server roles.

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
      
      remote = "#{chef_solo_remote}/data_bags/node"
      data,hosts,roles,options = { },{ },{ },{ }
      
      find_servers.each do |server|
        data[server.host.gsub(/\./,'_')] = {
          role:      role_names_for_host(server),
          fqdn:      server.options[:hostname] || server.host, 
          ipaddress: server.host,
          options:   server.options
        }
      end
      
      begin
        dir = run_locally(%{ mktemp -d /tmp/tempdatabag.XXXX }).chomp
        data.keys.each do |serv|
          File.open("#{dir}/#{serv}.json", "w") do |f|
            f.print(data[serv].merge({id: serv}).to_json
                    )
          end
        end
        upload_dir dir, remote
      ensure
        run_locally "rm -rf #{dir}"
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
  dir = capture( "echo #{chef_solo_remote}/data_bags/capistrano").chomp

  run "test -d #{dir} || mkdir -p #{dir}"
  vars = {}
  @variables.each { |k,v| vars[k] = v unless v.class == Proc }
  put vars.merge({ "id" => "config"}).to_json, "#{dir}/config.json"
end

