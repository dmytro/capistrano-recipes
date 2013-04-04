set_default(:postgresql_host, "localhost")
set_default(:postgresql_user) { application }
# set_default(:postgresql_password) { Capistrano::CLI.password_prompt "PostgreSQL Password: " }
set_default(:postgresql_database) { "#{application}_production" }

##
# Generate random password, since we won't be using PG outside of rails
#
set_default(:postgresql_password) { Array.new(20){rand(36).to_s(36)}.join }

psql = "#{sudo} -u postgres psql "

namespace :postgresql do

  create_yaml = false

  desc "Install the latest stable release of PostgreSQL."
  task :install, roles: :db, only: {primary: true} do
    run "#{sudo} add-apt-repository ppa:pitti/postgresql"
    run "#{sudo} apt-get -y update"
    run "#{sudo} apt-get -y install postgresql libpq-dev"
  end
  after "deploy:install", "postgresql:install"

  desc "Drop a database for this application."
  task :drop_database, roles: :db, only: {primary: true} do
    run %Q{#{psql} -c "drop database #{postgresql_database};"}
    run %Q{#{psql} -c "drop user #{postgresql_user};"}
  end

  desc "Create a database for this application."
  task :create_database, roles: :db, only: {primary: true} do
    #
    # Create role only if it does not exist
    # --------------------------------------------
    run %Q{#{psql} -tc "select count(*) from pg_roles where rolname = '#{postgresql_user}'"} do |channel, stream, data|
      if data.chomp.strip != "1" 
        run %Q{#{psql} -c "create user #{postgresql_user} with password '#{postgresql_password}';"}
        create_yaml = true
      end
    end
    
    #
    # Create DB only if it does not exist
    # --------------------------------------------
    run %Q{#{psql} -tc "select count(*) from pg_database where datname = '#{postgresql_database}'"} do |channel, stream, data|
      if data.chomp.strip != "1"
        run %Q{#{psql} -c "create database #{postgresql_database} owner #{postgresql_user};"}
      end
    end
  end
  after "deploy:setup", "postgresql:create_database"

  desc "Generate the database.yml configuration file."
  task :setup, roles: :app do
    if create_yaml
      run "mkdir -p #{shared_path}/config"
      template "postgresql.yml.erb", "#{shared_path}/config/database.yml"
    end
  end
  after "deploy:setup", "postgresql:setup"

  desc "Symlink the database.yml file into latest release"
  task :symlink, roles: :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
  after "deploy:finalize_update", "postgresql:symlink"
end
