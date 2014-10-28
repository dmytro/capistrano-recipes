#
# @author Dmytro Kovalov, dmytro.kovalov@gmail.com
#
namespace :chefsolo do

  desc <<-EOF

[internal] Set local cache for chef-solo.

Copy all chef-solo directory, custom chef-solo, assemble all databags
into single directory.

  Source File #{path_to __FILE__}

EOF
  task :setup do
    set :local_chef_cache_dir, run_locally(%{ mktemp -d /tmp/tempchef.XXXX }).chomp

    copy_dir bootstrap_path, local_chef_cache_dir, exclude: %w{./.git ./tmp}

    if exists?(:custom_chef_solo) && Dir.exists?(custom_chef_solo)
      copy_dir custom_chef_solo, local_chef_cache_dir, exclude: %w{./.git ./tmp}
    end

    top.chefsolo.databag.create

    set :chef_solo_setup_done, true
  end
end
