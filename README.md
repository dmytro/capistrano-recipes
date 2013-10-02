

Capistrano recipes
======================


This directory contains recipes to be used together with Capistrano. To use recipe in the deployment require needed file(s) from your `deploy.rb` file. 

**Note:** Do not automatically require all files. Some recipes implement same functionally differently depending on your requirements.


Description
-----------

Many cookbooks here are heavily modified after forking from original author. Main idea for new functionality is to provide means of integrating Capistrano with Chef-solo, where Capistrano is used for application deployment, and Chef is used for all infrastructure related tasks: bootstraping servers, installing software, etc.

This repository is closely related to another one (dmytro/chef-solo) and tested with it.

### Integration with chef-solo

#### Boostraping server

TBD 

#### Chef-solo roles and Capistrano roles

TBD 

#### Custom chef-solo setup

TBD 

#### Using Chef databags 

It is possible to use Chef databags in Capistrano recipes. Databags are loaded from either custom Chef-solo path or from standard one. If custom path is defined (variable `:custom_chef_solo` defined when recipe `custom_chef_solo` is loaded), then custom path is used.

* Example (see recipe mysql.rb):

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    root_password = get_data_bag(:users, "mysql")["root_password"]
    set :database, get_data_bag(:application, "database")
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* Limitations
  - Databags are loaded on the local server, which means that node attributes are not known.
  - No search functionality, only load


Recipes
-----------

### Base


- base.rb - this file is required. It sets some common methods used in other recipes.

#### Capistrano DSL extensions


File `base.rb` contains several extensions that can be useful  with Capistrano deployments (and also used in this recipes collection).

##### recipe

Load file with recipe by it's name. Just a helper.

##### upload_dir

Same as `upload` in Capistrano but for whole directory by tarring it locally and untarring remotely.

##### surun

Ask for `root` password and execute command remotely via `su -`. Fallback for the situations when sudo is not installed.

##### template

Helper to parse and upload to remote ERB template.

##### set_default

Set variable conditionally.

----

### Infrastructure and setup

#### Setup

- rbenv.rb - TODO
- setup.rb - Change ownership of the created directories at the setup stage
  - `:deploy:chown_dirs`

#### Remote logs

- logs.rb - Manage log/production.log file: tail and truncate

#### Sudo

- sudo.rb - Install sudo on the remote server. Do nothing if sudo installed.

#### Chef

- chef_solo.rb - 2 tasks
  - `chefsolo:deploy` - Run chef-solo deploy on the remote server (bootstrap server)
  - `chefsolo:run_remote` - deploy single JSON chef-solo file
- `chef_solo_roles.rb`
  - `chefsolo:roles` chef_solo_roles.rb - Deploy JSON file corresponding to role (uses `chefsolo:run_remote`)

#### Puppet

- puppet.rb

Similar to chef-solo above. Bootstraps puppet and provide task to execute manifest remotely. Puppet recipe requires chef-solo bootstrap.

#### HTTP Proxy

- File: http_proxy.rb

Setup HTTP proxy to access network via gateway server. HTTP server must have role `:proxy`, all other hosts configured as proxy clients.

----

### Web-servers and app.servers

#### nginx.rb

TODO: refactor install to use Chef

- **Template**
  - templates/nginx.conf.erb


#### nginx_monit.rb

Recipe to restart Nginx on systems with Monit

####  apache_unicorn.rb - Create virtual host for Apache with Unicorn
- **Templates**
  - templates/apache_unicorn_modules.json.erb
  - templates/apache_unicorn_virtual_host.conf.erb

#### unicorn.rb - Unicorn configuration for Nginx or Apache

- **Template**
      - templates/unicorn.rb.erb

#### puma.rb - TODO

----

### Databases

#### Generic (Sqlite)

- database.rb: Manage DB yaml config for Rails
  - `database:setup` Generate the database.yml configuration file.
  - `database:symlink`
  - **Template**
      - templates/database.yml.erb

#### Postgres

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

#### Memcached

- memcached.rb - TODO refactor to use Chef
  - **Template**
      - templates/memcached.erb


----

### Rails configuration

- application_yml_file.rb - Manage config/application.yml file: concatenate example and secrets files

----

### Rails assets

- Asset Precompile recipes - see {file:ASSETS_PRECOMPILE.md} for details
  - assets_precompile.rb
  - assets_precompile_conditional.rb
  - assets_precompile_local.rb

----


### Others and deprecated

- check.rb - deprecated
- fast.rb
- nodejs.rb - TODO: refactor install to use Chef
- talks.rb - TODO

