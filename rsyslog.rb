set_default :per_host_rsyslog_file, "/var/log/hosts/%HOSTNAME%.log"
set_default :all_hosts_rsyslog_file, "/var/log/hosts/all-hosts.log"
#
#
# ==================================================================

namespace :rsyslog do

  desc <<-DESC
Configure remote rsyslog - server and clients.

Recipe to manage remote logging using rsyslog. This recipe relies on
role :logger, at least one server in the current configuratuon should
have this role, if not it is skipped.

IP address or hostname of the logger host(s) is added on clinets to
forward logs to. On the server side UDP listener is configured, and
logs from server are stored in `/var/log/hosts/<HOSTNAME>.log` file
for each host.

Configuration
--------------

* :per_host_rsyslog_file - Filename for logging from remote hosts into
   file by hostname "/var/log/hosts/%HOSTNAME%.log". See templates for
   Rsyslog for more information. Set this variable to false to disable
   per host log file.

Default
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
set_default :per_host_rsyslog_file, "/var/log/hosts/%HOSTNAME%.log"
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* all_hosts_rsyslog_file - Same as above, but log everything into
   single file for the sake of easier uploading logs to, for example
   S3, using Fluentd.

Default
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
set_default :all_hosts_rsyslog_file, "/var/log/hosts/all-hosts.log"
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


Source #{path_to __FILE__}
Templates:
 - server: templates/rsyslog/udp_receiver.conf.erb
 - client: templates/rsyslog/remote_logger.conf.erb
DESC

  task :setup do

    loggers = find_servers(roles: [:logger])

    set :loggers, loggers
    unless loggers.empty?
      clients = find_servers - loggers

      template "rsyslog/udp_receiver.conf.erb", "/etc/rsyslog.d/udp_receiver.conf", options: { as: 'root', hosts: loggers}
      template "rsyslog/remote_logger.conf.erb", "/etc/rsyslog.d/remote_logger.conf", options: { as: 'root', hosts: clients}
      sudo "rm -f /etc/rsyslog.d/udp_receiver.conf", hosts: clients

      set :changed_rsyslog, true

    else
      logger.important "**** Remote logger is not defined. Not configuring rsyslog."
    end
  end

    desc <<-DESC
Install remote rsyslog configuration for Nginx.

This task does not have callbacks configured. You need to include
callback in your deploy.rb file explicitly to use it:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
after "rsyslog:setup", "rsyslog:nginx"
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Source #{path_to __FILE__}

DESC
  task :nginx do
    template "rsyslog/nginx.conf.erb", "/etc/rsyslog.d/10-nginx.conf", options: { as: 'root'}
    set :changed_rsyslog, true
  end

  desc <<-DESC
Restart rsyslog at the end of deployment.

Source #{path_to __FILE__}

DESC
  task :restart do
    sudo "/etc/init.d/rsyslog restart" if fetch(:changed_rsyslog, false)
  end
end

#
# Only restart if rsyslog config changed.
#
# on :start, :only => ["rsyslog:setup", "rsyslog:nginx", "deploy"] do
#   on :finish, "rsyslog:restart"
# end

before "chefsolo:exit_on_request", "rsyslog:restart"
on :finish, "rsyslog:restart"

after "chefsolo:roles", "rsyslog:setup"
