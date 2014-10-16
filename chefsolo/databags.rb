# -*- coding: utf-8 -*-

recipe "chefsolo/databags/cap"
recipe "chefsolo/databags/roles"
recipe "chefsolo/databags/secrets"

namespace :chefsolo do
  namespace :databag do

    task :create do
      top.chefsolo.databag.cap
      top.chefsolo.databag.roles
      top.chefsolo.databag.secrets if fetch(:use_s3_secrets, false)
    end
  end
end
