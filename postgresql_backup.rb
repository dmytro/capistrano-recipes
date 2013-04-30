namespace :postgresql do

  ##
  # Recipe to do backup of the remote PostgreSQL server. Uses
  # configuration from config/database.yml
  #
  # Automatically create pre/post backups on deploy
  #

  namespace :backup do 

    set :pg_backup_suffix, ''
    set :pg_backup_dir, "#{shared_path}/pg_backups"

    desc "Create directory for backup files"
    task :setup, :roles => :db, :only => { :primary => true } do 
      run "[ -d #{pg_backup_dir} ] || { mkdir -p #{pg_backup_dir}; chmod 700 #{pg_backup_dir} ; }"
    end
    
    desc "Dump remote production database NOTE: postgreSQL specific"
    task :production, :roles => :db, :only => { :primary => true } do

      # First lets get the remote database config file so that we can
      # read in the database settings
      begin 
        tmp_db_yml = %x{ mktemp /tmp/psql_backup_XXX }.chomp.strip
        get("#{shared_path}/config/database.yml", tmp_db_yml)
        
        # load the production settings within the database file
        db = YAML::load_file(tmp_db_yml)["production"]
      ensure
        File.delete tmp_db_yml
      end

      file = "#{pg_backup_dir}/#{db['database']}_dump.#{Time.now.strftime("%y%m%d.%H%M")}"+
        "#{pg_backup_suffix}.bz2"

      run "pg_dump --clean --no-owner --no-privileges -U#{db['username']} -h localhost #{db['database']} | bzip2 > #{file}" do |ch, stream, out|
        ch.send_data "#{db['password']}\n" if out =~ /^Password:/
        puts out
      end
    end

    task :production_pre , :roles => :db, :only => { :primary => true }  do 
      set :pg_backup_suffix, '.prerelease'
      postgresql.backup.production
    end
    
    task :production_post , :roles => :db, :only => { :primary => true }  do 
      set :pg_backup_suffix, '.postrelease'
      postgresql.backup.production
    end

    before 'deploy:migrate', 'postgresql:backup:production_pre'
    before 'deploy:reload', 'postgresql:backup:production_post'
    after  'deploy:setup', 'postgresql:backup:setup'

  end #backup
end
