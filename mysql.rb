set_default :mysql_databag_file, "database"
set_default :database_dump_location, "#{shared_path}/db/dumps"
set_default :database_dump_compress, false

##
# Perform dump of the database on the remote host. Credentials and
# DB name are passed by Hash database, with similar structrue as
# used in database.yml file.
#
# @param [Hash] database DB credentials
# @param [String] Rails environment used to generate file name of the dump.
#
# @return [String] filename of the dump.
#
def do_dump database, env=fetch(:rails_env)
  file = "#{fetch(:database_dump_location)}/#{application}_#{env}.#{Time.now.strftime "%Y%m%d%H%M"}.dump#{fetch(:database_dump_compress,false) ? '.bz2' : ''}"
  cmd = "mysqldump --user=#{database['username']} --host=#{database['host']} -p #{database['database']} #{fetch(:database_dump_compress,false) ? '| bzip2' : '' } > #{file}"
  run cmd do |ch, stream, out|
    ch.send_data "#{database['password']}\n" if out =~ /^Enter password:/
    puts out
  end
  file
end

##
# Read database dump file and load it to the DB.
#
# @param [String] file Full path to the dump file on remote host.
# @param [Hash] database Configuration hash for the DB to connect to.
#
def do_load file, database
  cat = file =~ /\.bz2/ ? "bunzip2 -c " : "cat "

  cmd = "#{cat} #{file} | mysql --host=#{ database['host']}  --user=#{database['username']} -p #{database['database']}"

  run cmd do |ch, stream, out|
    ch.send_data "#{database['password']}\n" if out =~ /^Enter password:/
    puts out
  end
end

##
# Read curent DB config from remote database.yml file
#
# @return [Hash] database.yml part corresponding to the environment.
#
def current_db_config env=fetch(:rails_env)
  begin
    tmp_db_yml = %x{ mktemp /tmp/database_yml_XXX }.chomp.strip
    get("#{shared_path}/config/database.yml", tmp_db_yml)
    database = YAML::load_file(tmp_db_yml)[env]
  ensure
    File.delete tmp_db_yml
  end
  database
end

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
# ========================================================================================
  desc <<-DESC
[internal] Setup dump directory for MySQL database.

Source #{path_to __FILE__}

DESC

  task :setup_dump, roles: [:db], only: { primary: true } do
    sudo "mkdir -p #{fetch(:database_dump_location)}"
    sudo "chown #{user} #{fetch(:database_dump_location)}"
  end

# ========================================================================================

  desc <<-DESC
  Generate and install `config/database.yml` file.

  Configuration
  -------------

  * All setup information is read from databag :application, with item
    name defained by :mysql_databag_file variable; by default
    :mysql_databag_file is set to `database`. Change it to match your
    environment configuration properly.

Databag format
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    "id" : "database",
    "name" : "user",
    "user" : "user",
    "password" : "SECRET",
    "host" : "192.168.1.1"
}
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Note: "host" attribute can be ommited from the databag. In this case
name of the server with { role: :db, primary: true } is used.


  * set :database_yml_create, false - prevent from generating file.

  * CLI options: use `-S database_yml_create=false` if you don't want
    database.yml file generated.


  Source file: #{path_to __FILE__}
  Template:    mysql/database.yml.erb

DESC

  task :database_yml, roles: [:db, :app, :web], :on_no_matching_servers => :continue do
    set :database, get_data_bag(:application, mysql_databag_file)

    database['host'] = find_servers(roles: :db, primary: true).first.host unless database['host']

    template "mysql/database.yml.erb", "#{shared_path}/config/database.yml"
    try_sudo "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/"
  end



  namespace :dump do
    # ========================================================================================

    desc <<-DESC
Dump current environment's database.

Currently configured server found with { roles: :db, primary: true }
is dumped to :database_dump_location.

Configuration
-------------

* :database_dump_location - directory for storing dumps

* :database_dump_compress - true/false. If true then calls bzip2 to compress output dump file.

* Credentials are read from database.yml file on the target server.

Output
-----------

* Output file stored in the timestamped file. File name consists of
  :application, :rails_env, timestamp YYYYMMDDHHMM, and suffix 'bz2'
  if compression is enabled.

* Task sets variable :database_dump_outfile - full path to the file on
  remote host.

Source #{path_to __FILE__}

DESC
    task :current, roles: [:db], only: { primary: true } do
      database = current_db_config
      set :database_dump_outfile, do_dump(database)
    end

    # ========================================================================================

    desc  <<-DESC
Copy dump file produced by mysql.dump.current to local host.

File is stored with the same name as remote dump file in the current
directory.

Source #{path_to __FILE__}

DESC

    task :copy_local, roles: [:db], only: { primary: true }  do
      top.mysql.dump.current
      remote = fetch(:database_dump_outfile, false)
      if remote
        get remote, File.basename(remote)
        logger.important " Copied remote MySQL dump to local file #{File.basename(remote)}"
      end
    end

    # ========================================================================================
    desc <<-DESC
Dump PRODUCTION database to current environment's database server directory.

Current DB server found with { roles: :db, primary: true } is dumped
to :database_dump_location. Production DB configuratiopn need to be
provided separately in a databag.

Configuration
-------------

* See attributes of mysql:dump:current.

* Credentials for production database are read from databag
  :application with item name :production_database.

Output
-----------

* Same as `mysql:dump:current` task's.

Source #{path_to __FILE__}

DESC
    task :production, roles: [:db], only: { primary: true } do
      database = get_data_bag(:application, 'production_database')

      set :database_dump_outfile, do_dump(database, 'production')
    end


  end # namespace :dump

  # ========================================================================================

  namespace :read do
    desc <<-DESC
Load PRODUCTION dump to current environment DB.

Source #{path_to __FILE__}
DESC
    task :production, roles: [:db], only: { primary: true }  do
      production = get_data_bag(:application, 'production_database')
      current  = current_db_config

      if current['host'] == production['host'] && current['database'] == production['database']
        raise  "Check what you are doing. Can't dump and load to the same DB."
      end

      file = do_dump production, 'production'
      do_load file, current

    end

  end # namespace :load


  ########################################################################################

  after "depoy:setup", "mysql:setup_dump"
  before "deploy:migrate", "mysql:setup"
  before "deploy:migrate", "mysql:database_yml" unless fetch(:database_yml_create, false)

end
