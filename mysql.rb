namespace :mysql do 
  
  desc <<-DESC
  Create database, database user, and set grant permissions.

  By default database creation is not attempted. To force DB creation
  you need to define server with attribute `create_db: true`, also
  this server must be defined as primary. Example:

  server '10.0.x.x', :db, :mysql, primary: true, create_db: true # db-test


  Source file: #{__FILE__}
DESC
  task :setup, only: { primary: true, create_db: true }, :on_no_matching_servers => :continue do
    sql = "/tmp/mysql_createdb.sql"

    set :hosts, (find_servers(:roles => [:web, :app, :db]) << 'localhost')
    root_password = get_data_bag(:users, "mysql")["root_password"]
    set :database, get_data_bag(:application, "database")

    begin
      template "mysql_createdb.sql.erb", sql
      run "mysql -u root -p#{root_password} < #{sql}"
    ensure
      run "cat /tmp/mysql_createdb.sql"
      run "rm -f /tmp/mysql_createdb.sql"
    end
  end
end

before "deploy:migrate", "mysql:setup"
