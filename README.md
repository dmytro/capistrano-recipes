

Capistrano recipes
======================


This directory contains recipes to be used together with Capistrano. To use recipe in the deployment require needed file(s) from your `deploy.rb` file. **Note:** Do not automatically require all files. Some recipes implement same functionalily differently dependint on your requirements.

Recipes
-----------

- base.rb - this file is required. It sets some common methods used in other recipes.

- nginx_monit.rb - Recipe to restart Nginx on systems with Monit

- apache_unicorn.rb - Create virtual host for Apache with Unicorn
  - **Templates**
      - templates/apache_unicorn_modules.json.erb
      - templates/apache_unicorn_virtual_host.conf.erb

- application_yml_file.rb - Manage config/application.yml file: concatenate example and secrets files

- Asset Precompile recipes - see {file:ASSETS_PRECOMPILE.md} for details
  - assets_precompile.rb
  - assets_precompile_conditional.rb
  - assets_precompile_local.rb

- check.rb - deprecated
- chef_solo.rb - 2 tasks
  - `chefsolo:deploy` - Run chef-solo deploy on the remote server (bootstrap server)
  - `chefsolo:run_remote` - deploy sigle JSON chef-solo file
- `chefsolo:roles` chef_solo_roles.rb - Deploy JSON file corresponding to role (uses `chefsolo:run_remote`)

- database.rb: Manage DB yaml config for Rails
  - `database:setup` Generate the database.yml configuration file.
  - `database:symlink`
  - **Template**
      - templates/database.yml.erb

  
- fast.rb 
- logs.rb - Manage log/production.log file: tail and truncate
- memcached.rb - refactor to use Chef
  - **Template**
      - templates/memcached.erb
- nginx.rb - TODO: refactor install to use Chef
  - **Template**
      - templates/nginx.conf.erb
    
- nodejs.rb - TODO: refactor install to use Chef
- postgresql.rb - Manage Postgres for Rails (namespace `:postgresql`)
  - `:install` - TODO: refactor install to use Chef
  - `:drop_database`
  - `:create_database`
  - `:setup`
  - `:symlink`
  - **Template**
      - templates/postgresql.yml.erb
- postgresql_backup.rb - Backup remote PostgreSQL server. Automatically create pre/post backups on deploy. Namespace `:postrgresql`.
  - `:setup`
  - `:production`
  - `:production_pre`
  - `:production_post`
- puma.rb - TODO
- rbenv.rb - TODO
- setup.rb - Change ownership of the created directories at the setup stage
  - `:deploy:chown_dirs` 
- sudo.rb - Install sudo on the remote server. Do nothing if sudo installed.
- talks.rb - TODO
- unicorn.rb - Unicorn configuration for Nginx or Apache 
  - **Template**
      - templates/unicorn.rb.erb
