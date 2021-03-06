#
# @author Dmytro Kovalov, dmytro.kovalov@gmail.com
#
namespace :chefsolo do

  desc <<-EOF
   Install chef-solo and configuration on remote server(s).

   Task needs chef-solo repository git@github.com:dmytro/chef-solo.git
   installed as git submodule or directory.

   Configuration and defaults
   --------------------------

    * set :bootstrap_path, <PATH>

      Local PATH to the directory where, chef-solo is installed. By
      default searched in ../chef-solo/

    * set :chef_solo_json, "empty.json"

      JSON configuration for Chef solo to deploy. Defaults to
      empty.json

    * set :custom_chef_solo, File.expand_path (...)

      Full path to the directory with custom chef-solo configuration.
      If set recipe will copy custom configuration to the remote host
      into the same directory where chef-solo is installed, therefore
      adding or overwriting files in chef-solo repository.

      Default: not set

    * set_default :chef_solo_remote,     "~/chef"

      Remote location where chef-solo is installed. By default in
      ~/chef directory of remote user.

    * set_default :chef_solo_command, \\
      %Q{cd #{chef_solo_remote} && #{try_sudo} chef-solo --config #{chef_solo_remote}/solo.rb --json-attributes }

      Remote command to execute chef-solo.  Use it as: `run
      chef_solo_command + 'empty.json'` in your recipes.

  Configuration
  -------------

  set `-S chef_solo_bootstrap_skip=true` to skip execution of this task.

  RVM
  -----

  In case chef-solo is not found or can't initiaize environment
  properly when used with sudo, use rvmsudo instead. You also
  prbably'd need to set rvmsudo_secure_path and PATH, some commands
  are failing when started from /usr/bin/env

  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  set :sudo, 'rvmsudo'

  set :default_environment, {
      'rvmsudo_secure_path' => 1,
      'PATH' => '/usr/local/rvm/gems/ruby-2.0.0-p247/bin: \\
       /usr/local/rvm/gems/ruby-2.0.0-p247@global/bin:\\
       /usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin',
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Source File #{path_to __FILE__}

EOF
  task :deploy do

    # Limit execution to only hosts in the list if list provided
    options = { shell: :bash, pty: true }
    options.merge! hosts: only_hosts if exists? :only_hosts

    unless fetch(:chef_solo_bootstrap_ran, false)

      tag = fetch(:capiche_release_tag, %x{git rev-parse HEAD}).chomp

      open("#{local_chef_cache_dir}/CAPICHE_RELEASE", "w") do |f|
        f.print tag
        f.close
      end

      # make sure directories are cleaned between runs
      run "(cd #{chef_solo_remote} && #{sudo} rm -rf cookbooks site-cookbooks data_bags); true "
      upload_dir local_chef_cache_dir, chef_solo_remote, options: options

      unless chef_solo_bootstrap_skip
        top.chefsolo.roles
        set :chef_solo_bootstrap_ran, true # Make sure that deploy of chef-solo never runs twice
      end

    end
  end
end
