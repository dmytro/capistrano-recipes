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
  file = "#{fetch(:database_dump_location)}/#{application}_#{server_environment}.#{Time.now.strftime "%Y%m%d%H%M"}.dump#{fetch(:database_dump_compress,false) ? '.bz2' : ''}"
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
  database = { }

  if server_environment =~ /^prod/
      database = get_data_bag(:application, 'production_database')    
  else
    begin
      tmp_db_yml = %x{ mktemp /tmp/database_yml_XXX }.chomp.strip
      get("#{shared_path}/config/database.yml", tmp_db_yml)
      database = YAML::load_file(tmp_db_yml)[env]
    ensure
      File.delete tmp_db_yml
    end
  end
  database
end

namespace :mysql do 
  namespace :dump do
    # help
    desc <<-DESC
Show common help for all DB dump tasks.

All tasks in mysql:dump:* namespace can dump database to file, copy
file from remote host, or load dump file to target database. 

All dump and load operations are done on the server in the current
environment specified by role { roles: :db, primary: true }.

All tasks require current environment name prepended before task name: 
cap <env> <task>

Tasks
===========

* cap <env> mysql:dump:remote 

  Dump remote DB and save it on remote :primary host. Dump directory
  defined by variable :database_dump_location (see below).

* cap <env> mysql:dump:localhost

  Same as above, after finishing dump copy it to the localhost. On the
  local dump file is store in the current directory.

* cap <env> mysql:dump:production:and_load 

  Dump production database and load to current environment (it
  explicitly excludes production, to avoid mistakenly load of the DB
  dump to production)

* cap <env> mysql:load_db -s mysql_dump=[...]  

  Load DB to current environment server from local file. Specify file
  on the command line.

* cap <env> mysql:dump:help - this task. Only displays this help, does
  nothing.

* cap <env> mysql:dump:setup 

  [internal] - Internal task that creates dump directory on remote
  server. Usually one does not need to call this task, it is executed
  before dump.

Configuration
=============

Capistrano variables controlling dump:

* :database_dump_location - directory for storing dumps (on the remote
  server); Default: "#{shared_path}/db/dumps"

* :database_dump_compress - true/false. If true then calls bzip2 to
  compress output dump file. Default: false

* Credentials are read from database.yml file on the server where dump
  or load is done. Exception is production dump tasks, where DB
  information is read from databag, dump in production is done using
  read-only replica.

Output
-----------

* Output file stored in the timestamped file. File name consists of
  :application, :server_environment, timestamp YYYYMMDDHHMM, and
  suffix 'bz2' if compression is enabled.

* Task sets variable :database_dump_outfile - full path to the file on
  remote host (used to copy file to local host).

Source: #{path_to __FILE__}
DESC
    task :help do
    end

    desc <<-DESC
[internal] Setup dump directory for MySQL database.

On remote server for the current environment.

Source #{path_to __FILE__}
DESC

    task :setup, roles: [:db], only: { primary: true } do
      sudo "mkdir -p #{fetch(:database_dump_location)}"
      sudo "chown #{user} #{fetch(:database_dump_location)}"
    end


    # ========================================================================================

    desc <<-DESC
Dump database for the current environment.

Source #{path_to __FILE__}
DESC
    task :remote, roles: [:db], only: { primary: true } do
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

    task :localhost, roles: [:db], only: { primary: true }  do
      top.mysql.dump.setup
      top.mysql.dump.remote
      file = fetch(:database_dump_outfile, false)
      if file
        get file, File.basename(file)
        logger.important "*** Saved #{server_environment} MySQL dump to local file #{File.basename(file)}"
      end
    end

  # ========================================================================================

    namespace :production do
      desc "TODO: Dump production and load to cuurent env "
      task :and_load do 
      end
    end                         # production
    
    desc "TODO: load DB dump file to current environment"
    task :load_db do 
    end

  end                           # dump
end                             # mysql
after "mysql:setup", "mysql:dump:setup"
