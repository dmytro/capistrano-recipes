# @author Dmytro Kovalov dmytro.kovalov@gmail.com
#
# Oct 2013, Tokyo
#
# Capistrano config for Paperclip gem. Include this recipe
# in your deploy.rb
#

set_default :paperclip_dir, "public/uploads"

namespace :paperclip do

  desc <<-DESC
Create directory for the Paperclip uploads.

For your Paperclip configuration add path to the directory in
`application.rb` as:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    config.paperclip_defaults = { 
      :path => ":rails_root/public/uploads/:class/:attachment/:id/:style/:filename"
    }
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Source: #{path_to __FILE__}

DESC

  desc <<-DESC
Symlink paperclip directory to cuurent release.

Source: #{path_to __FILE__}

DESC
  task :setup do 
    try_sudo "mkdir -p #{shared_path}/#{paperclip_dir}"
    sudo "chown -R #{user} #{shared_path}/#{paperclip_dir}"
  end

  task :symlink do
    run "rm -rf #{release_path}/#{paperclip_dir}"
    run "ln -nfs #{shared_path}/#{paperclip_dir} #{release_path}/#{File.dirname paperclip_dir}"
  end

end

after "deploy:finalize_update", "paperclip:symlink"
after "deploy:setup", "paperclip:setup"
