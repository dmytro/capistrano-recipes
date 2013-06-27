

Capistrano recipes
======================


This directory contains recipes to be used together with Capistrano. To use recipe in the deployment require needed file(s) from your `deploy.rb` file. **Note:** Do not automatically require all files. Some recipes implement same functionalily differently dependint on your requirements.

Recipes
-----------

- base.rb - this file is required. It sets some common methods used in other recipes.

- apache_unicorn.rb - Create virtual host for Apache with Unicorn
  - Templates
      - templates/apache_unicorn_modules.json.erb
      - templates/apache_unicorn_virtual_host.conf.erb

- application_yml_file.rb - Manage config/application.yml file: concatenate example and secrets files

- Asset Precompile recipes - see {file:ASSETS_PRECOMPILE.md} for details
  - assets_precompile.rb
  - assets_precompile_conditional.rb
  - assets_precompile_local.rb

- check.rb - deprecated
- chef_solo.rb - 2 tasks
  - "chefsolo:deploy" - Run chef-solo deploy on the remote server (bootstrap server)
  - "chefsolo:run_remote" - deploy sigle JSON chef-solo file
- "chefsolo:roles" chef_solo_roles.rb - Deploy JSON file corresponding to role (uses "chefsolo:run_remote")

- database.rb: Manage DB yaml config for Rails
  - "database:setup" Generate the database.yml configuration file.
  - "database:symlink"
  
- fast.rb
- logs.rb - Manage log/production.log file: tail and truncate
- memcached.rb - refactor to use Chef
- nginx.rb - TODO: refactor install to use Chef
- nodejs.rb - TODO: refactor install to use Chef
- postgresql.rb
- postgresql_backup.rb
- puma.rb
- rbenv.rb
- setup.rb
- sudo.rb
- surun.rb
- talks.rb
- unicorn.rb


- templates/database.yml.erb
- templates/memcached.erb
- templates/nginx.conf.erb
- templates/postgresql.yml.erb
- templates/unicorn.rb.erb
