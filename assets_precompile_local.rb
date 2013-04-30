namespace :deploy do
  namespace :assets do
    
    desc "Precompile locally and deploy the assets to the server"
    task :precompile, :roles => :web, :except => { :no_release => true } do
      run_locally "#{rake} RAILS_ENV=#{rails_env} RAILS_GROUPS=assets assets:precompile"
      run "mkdir -p #{release_path}/public/assets"
      transfer(:up, "public/assets", "#{release_path}/public/assets") { print "." }
      run_locally "rm -rf public/assets"    # clean up to avoid conflicts with development-mode assets
    end
    
    after "deploy:migrate", "deploy:assets:precompile"

  end
end
