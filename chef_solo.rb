namespace :chefsolo do 
  desc <<-EOF
   Run chef-solo deploy onto the remote server.

   Task needs chef-solo repository installed as git submodule in
   config/deploy/chef-solo, and uses SSH key authentication.

EOF
  task :deploy, roles: :app do
    dir = File.expand_path("../chef-solo/", File.dirname(__FILE__))
    stdout = run_locally %Q{ssh-agent /bin/bash -c "cd #{dir} && ssh-add #{ssh_options[:keys][0]} && CUSTOM_SSH_OPTIONS='-F /dev/null' ./deploy.sh #{user}@#{host}"}
    puts "OUTPUT:" + stdout
  end

  before "deploy:install", "chefsolo:deploy"
end
