#
# @author Dmytro Kovalov, dmytro.kovalov@gmail.com
#
require 'json'
require "aws/s3"

set_default :chef_solo_json,           "empty.json"
set_default :chef_solo_remote,         "~#{user}/chef"
set_default :chef_solo_command,        %Q{cd #{chef_solo_remote} && #{try_sudo} chef-solo --config #{chef_solo_remote}/solo.rb --json-attributes }
set_default :chef_solo_bootstrap_skip, false
set_default :chef_solo_roles_skip,     false

set_default :use_s3_secrets,           false
set_default :s3_secret_databag_path,   "/secrets/data_bags/"
set_default :s3_region,                "ap-northeast"

recipe "chefsolo/cleanup"
recipe "chefsolo/databags"
recipe "chefsolo/deploy"
recipe "chefsolo/exit_on_request"
recipe "chefsolo/roles"
recipe "chefsolo/setup"

on :start,  "chefsolo:setup",   :except => config_names
on :finish, "chefsolo:cleanup", :except => config_names

before "deploy",       "chefsolo:deploy"
after  "deploy:setup", "chefsolo:exit_on_request" if fetch(:only_infra, false)
