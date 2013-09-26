
namespace :chefsolo do

  desc <<-EOF
Deploy JSON file(s) to server corresponding to servers' role(s)

This recipe will find all roles the target server has and try to
deploy to the server JSON file(s) corresponding to server role(s). If
servers defined as:

role :db, db01.example.com
role :web, web01.example.com

this recipe will deploy role `db.json` to db01 and `web.json` to
web01.

EOF

  task :roles do 

    json_path = exists?(:custom_chef_solo) ? custom_chef_solo : chef_solo_path

    servers = exists?(:only_hosts) ? Array(only_hosts) : find_servers_for_task(current_task)
    servers.each do |server|
      role_names_for_host(server).each do |role|
        file = "#{role.to_s}.json"
        if File.exists? "#{json_path}/#{file}"
          parallel do |session|
            session.when "server.host == '#{server}'", "#{chef_solo_command} #{chef_solo_remote}/#{file}"
          end
        end
      end
    end
  end

  
end

before "chefsolo:roles", "chefsolo:deploy"
