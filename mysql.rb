set_default :mysql_databag_file, "database"

namespace :mysql do 
  
  desc <<-DESC
  Create database, database user, and set grant permissions.

  By default database creation is not attempted. To force DB creation
  you need to define server with attribute `create_db: true`, also
  this server must be defined as primary. Example:

  server '10.0.x.x', :db, :mysql, primary: true, create_db: true 


  Source file: #{path_to __FILE__}
  Template:    mysql/mysql_createdb.sql.erb

DESC
  task :setup, only: { primary: true, create_db: true }, :on_no_matching_servers => :continue do
    sql = "/tmp/mysql_createdb.sql"

    set :hosts, (find_servers(:roles => [:web, :app, :db]) << 'localhost')
    root_password = get_data_bag(:users, "mysql")["root_password"]
    set :database, get_data_bag(:application, mysql_databag_file)

    begin
      template "mysql/mysql_createdb.sql.erb", sql
      run "mysql -u root -p#{root_password} < #{sql}"
    ensure
      run "cat /tmp/mysql_createdb.sql"
      run "rm -f /tmp/mysql_createdb.sql"
    end
  end

  desc <<-DESC
  Generate and install `config/database.yml` file.

  Configuration
  -------------

  * All setup information is read from databag :application, with item
    name defained by :mysql_databag_file variable; by default
    :mysql_databag_file is set to `database`. Change it to match your
    environment configuration properly.

  * set :database_yml_create, false - prevent from generating file.

  * CLI options: use `-S database_yml_create=false` if you don't want
    database.yml file generated.


  Source file: #{path_to __FILE__} 
  Template:    mysql/database.yml.erb



DESC

  task :database_yml, roles: [:db, :app, :web], :on_no_matching_servers => :continue do
    set :database, get_data_bag(:application, mysql_databag_file)
    template "mysql/database.yml.erb", "#{shared_path}/config/database.yml"
    try_sudo "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/"
  end

end

before "deploy:migrate", "mysql:setup"
before "deploy:migrate", "mysql:database_yml" unless fetch(:database_yml_create, false)
