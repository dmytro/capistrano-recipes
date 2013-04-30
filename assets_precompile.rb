namespace :deploy do
  namespace :assets do

    desc <<-DESC
      The task precompiles the Rails assets from the \
      Rails 3.1 asset pipeline.
    DESC
    task :precompile, :roles => :web, :except => { :no_release => true } do
        run %Q{cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} assets:precompile}
    end

  end
end
