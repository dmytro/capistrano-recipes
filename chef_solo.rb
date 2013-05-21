#
# @author Dmytro Kovalov, dmytro.kovalov@gmail.com
# 
set_default :chef_solo_path, File.expand_path("../chef-solo/", File.dirname(__FILE__))
set_default :chef_solo_json, "empty.json"

namespace :chefsolo do 

  desc <<-EOF
   Run chef-solo deploy on the remote server.

   Task needs chef-solo repository git@github.com:dmytro/chef-solo.git
   installed as git submodule or directory.

   Configuration:

    * set :chef_solo_path, <PATH> 

      Path to the directory where, chef-solo is
      installed. If not defined would search in
      ./config/deploy/chef-solo

    * set :chef_solo_json, "file.json"

      JSON configuration for Chef solo to deploy. Defaults to
      empty.json


EOF
  task :deploy do
    temp = %x{ mktemp /tmp/captemp-tar.XXXX }.chomp

    run_locally "cd #{chef_solo_path} && tar cfz #{temp} . "
    upload( temp, temp, :via => :scp)
    run_locally "rm -f #{temp}"

    run "mkdir -p ~/chef && cd ~/chef && tar xfz #{temp} && rm -f #{temp}"    
    run "#{try_sudo} cd ~/chef && bash ./install.sh #{chef_solo_json}"
  end


  before "deploy", "chefsolo:deploy"
end
