
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

    find_servers_for_task(current_task).each do |server|
      role_names_for_host(server).each do |role|
        file = "#{role.to_s}.json"
        run  "#{chef_solo_command}#{file}" if File.exists? "#{chef_solo_path}/#{file}" # ! No space between chef_solo_command and file !
      end
    end
  end

  before "deploy", "chefsolo:roles"
#  before "chefsolo:roles", "chefsolo:deploy"
  
end
