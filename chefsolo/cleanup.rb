#
# @author Dmytro Kovalov, dmytro.kovalov@gmail.com
#
namespace :chefsolo do

  desc <<-EOF

[internal] Cleam local chef-solo cache after deploy.

  Source File #{path_to __FILE__}

EOF
  task :cleanup do
    run_locally(%{ rm -rf #{ local_chef_cache_dir }})
    unset :local_chef_cache_dir
  end

end
