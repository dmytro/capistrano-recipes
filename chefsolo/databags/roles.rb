# -*- coding: utf-8 -*-

namespace :chefsolo do
  namespace :databag do

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
              name:                 server.host,
              role:                 role_names_for_host(server), # 2 entires for roles `role` used by Munin, `roles` by Nagios
              roles:                role_names_for_host(server),
              fqdn:                 server.options[:hostname] || server.host,
              ipaddress:            ip_address,
              os:                   server.options[:os] || 'linux', # TODO get real os of :node
              chef_environment:     fetch(:chef_environment)
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
  end
end
