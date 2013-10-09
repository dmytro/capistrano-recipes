set_default :chef_solo_roles_skip, false

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

Configuration:

- To skip infra roles process use: cap -s chef_solo_roles_skip=true ...

Source File #{path_to __FILE__}

EOF

  task :roles do 
    json_path = exists?(:custom_chef_solo) ? custom_chef_solo : chef_solo_path

    roles = find_servers_for_task(current_task).map do |current_server|
      role_names_for_host(current_server)
    end.flatten.uniq
    
    roles.each do |role|
      file = "#{role.to_s}.json"
      logger.important "Deploying role #{role}"
      run "#{chef_solo_command} #{chef_solo_remote}/#{file}", :roles => [role] if File.exists? "#{json_path}/#{file}"
    end
  end                           # :roles
  
  desc "Stop after executing chefsolo:roles"
  task :no_release do
    logger.info "Infra deployed. Stopping on user request."
    exit
  end
end

after  "chefsolo:roles", "chefsolo:no_release" if fetch(:infra_only, false)
before "chefsolo:roles", "chefsolo:deploy" unless fetch(:chef_solo_roles_skip, true)
before "deploy", "chefsolo:roles"          unless fetch(:chef_solo_roles_skip, true)
