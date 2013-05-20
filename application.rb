namespace :application_yml do
  
  desc "Setup application.yml file"
  task :setup do
    run "cat #{shared_path}/config/application.secrets.yml #{shared_path}/config/application.example.yml > #{shared_path}/config/application.yml"
  end
  before "application_yml:setup", "application_yml:upload_yml"

  desc "Upload application.*.yml files"
  task :upload_yml do
    %w{ secrets example}.each do |file|
      upload "#{%x{pwd}.chomp}/config/application.#{file}.yml", "#{shared_path}/config/application.#{file}.yml"
    end
  end

  desc "Symlink the application.yml file into latest release"
  task :symlink do
    run "ln -nfs #{shared_path}/config/application.yml #{release_path}/config/application.yml"
  end
  after "deploy:finalize_update", "application_yml:symlink"


end
