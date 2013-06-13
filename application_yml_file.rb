#
# Manage config/application.yml file: concatenate example and secrets
# files.
namespace :application_yml do
  
  desc "Setup application.yml file"
  task :setup do
    run "cd #{release_path} && rake setup:config:config/application.yml"
  end
  after "bundle:install", "application_yml:setup"
  before "application_yml:setup", "application_yml:upload_yml"

  desc "Upload application.*.yml files"
  task :upload_yml do
    %w{ secrets example}.each do |file|
      run_locally "test -f  #{%x{pwd}.chomp}/config/application.#{file}.yml || touch #{%x{pwd}.chomp}/config/application.#{file}.yml"
      upload "#{%x{pwd}.chomp}/config/application.#{file}.yml", "#{shared_path}/config/application.#{file}.yml"
    end
  end

  desc "Symlink the application.yml file into latest release"
  task :symlink do
    run "ln -nfs #{shared_path}/config/application.yml #{release_path}/config/application.yml"
  end
  after "deploy:finalize_update", "application_yml:symlink"


end
