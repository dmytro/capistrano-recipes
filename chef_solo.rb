#
# @author Dmytro Kovalov, dmytro.kovalov@gmail.com
# 

set_default :chef_solo_path,       File.expand_path("../chef-solo/", File.dirname(__FILE__))
set_default :chef_solo_json,       "empty.json"
set_default :chef_solo_remote,     "~/chef"
set_default :chef_solo_command,    %Q{cd #{chef_solo_remote} && #{try_sudo} chef-solo --config #{chef_solo_remote}/solo.rb --json-attributes }

namespace :chefsolo do 

  desc <<-EOF
   Run chef-solo deploy on the remote server.

   Task needs chef-solo repository git@github.com:dmytro/chef-solo.git
   installed as git submodule or directory.

   Configuration adn defaults
   --------------------------

    * set :chef_solo_path, <PATH> 

      Local PATH to the directory where, chef-solo is installed. By
      default searched in ./config/deploy/chef-solo

    * set :chef_solo_json, "empty.json"

      JSON configuration for Chef solo to deploy. Defaults to
      empty.json

    * set_default :chef_solo_remote,     "~/chef"

      Remote localtion where chef-solo is installed. By default in
      ~/chef directory of remote user.

    * set_default :chef_solo_command, \
      %Q{cd #{chef_solo_remote} && #{try_sudo} chef-solo --config #{chef_solo_remote}/solo.rb --json-attributes }

      Remote command to execute chef-solo.  Use it as: `run
      chef_solo_command + 'empty.json'` in your recipes.



EOF
  task :deploy do
    temp = %x{ mktemp /tmp/captemp-tar.XXXX }.chomp

    run_locally "cd #{chef_solo_path} && tar cfz #{temp} . "
    upload( temp, temp, :via => :scp)
    run_locally "rm -f #{temp}"

    run "mkdir -p #{chef_solo_remote} && cd #{chef_solo_remote} && #{try_sudo} tar xfz #{temp} && rm -f #{temp}", :shell => :bash
    run "cd #{chef_solo_remote} && #{try_sudo} bash ./install.sh #{chef_solo_json}", :shell => :bash
  end
  
  desc "Run chef-solo caommand remotely. Specify JSON file as: -s json=<file>"
  task :run_remote do
    run chef_solo_command + (json ? json : "empty.json")
  end

  before "deploy", "chefsolo:deploy"
end
