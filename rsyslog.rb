

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
  end

  desc <<-DESC
Restart rsyslog at the end of deployment.

Source #{path_to __FILE__}

DESC
  task :restart do 
    sudo "/etc/init.d/rsyslog restart"
  end
end

#
# Only restart if rsyslog config changed.
#
on :start, :only => ["rsyslog:setup", "rsyslog:nginx"] do
  on :finish, "rsyslog:restart"
end

after "deploy:setup", "rsyslog:setup"
