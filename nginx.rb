set_default(:nginx_port, 80)
set_default(:nginx_error_pages, true)
set_default(:nginx_chrome_frame, true)
set_default(:domain_name, "#{application}")
set_default(:nginx_access_log, "#{shared_path}/log/nginx_#{application}_access.log")
set_default(:nginx_error_log, "#{shared_path}/log/nginx_#{application}_error.log")

set_default(:nginx_redirect_on_http_x_forwarded_proto, false)
set_default(:htpasswd_file, "#{shared_path}/config/htpasswd")

namespace :nginx do

  desc <<-DESC
Setup nginx configuration for this application.

Confoiguration template is for using Nginx with Unicorn. For other
uses, this needs to be changed.

Configuration varaibles
------------------------

- :nginx_port - default 80, port to listen

- :nginx_error_pages

- :nginx_chrome_frame

- :nginx_access_log - PATH to access log file, by default
  "#{shared_path}/log/nginx_#{application}_access.log"

- :nginx_error_log- PATH to error log file, by default
  "#{shared_path}/log/nginx_#{application}_error.log"

- :enable_basic_auth - true/false.

- :htpasswd_file - PATH to basic auth htpasswd file (managed by
  separate recipe - htpasswd.rb), can be used both by apache and
  nginx.

- :nginx_redirect_on_http_x_forwarded_proto (true/false) - Set this to
  `true` to use X-Forwarded-Proto header to redirect to https HTTP
  requests.

  Example usage: ELB on AWS sets this header when SSL is terminated on
  it. In this case Nginx behind the ELB can redirect to HTTPS.

  Default: false

- :nginx_pass_server_header - set to true to enable hiding 'Server:'
  header of Nginx.

  Default: false


Source #{path_to __FILE__}

DESC
  task :setup, roles: [:app, :web], except: { no_release: true } do
    template "nginx.conf.erb", "/tmp/nginx_conf"
    try_sudo "mkdir -p #{shared_path}/config"
    sudo "mkdir -p /etc/nginx/sites-enabled/"
    sudo "mv /tmp/nginx_conf /etc/nginx/sites-enabled/#{application}"
    sudo "rm -f /etc/nginx/sites-enabled/default"
  end
  after "deploy:setup", "nginx:setup"

  %w[start stop restart reload].each do |command|
    desc "#{command.capitalize} Nginx server"
    task command.to_sym, roles: [:app, :web], except: { no_release: true }  do
      sudo "service nginx #{command}"
    end
    # TODO: Don't restart Nginx on deploy:restart. Find way to change
    # TODO: it to reload, instead.
    # TODO: after "deploy:#{command}", "nginx:#{command}"
    #
    after "deploy:start",  "nginx:start"
    after "deploy:reload",  "nginx:reload"
    after "deploy:restart", "nginx:reload"
  end

  desc <<-DESC
Ensure Apache is not running in case it is installed.

Source #{path_to __FILE__}
DESC
  task :apache_stop, roles: [:app, :web], except: { no_release: true }, :on_no_matching_servers => :continue  do
    %w{ apache2 apache httpd }.each do |serv| # Different names for apache in varios distros
      sudo "service #{serv} stop || true"
    end
  end
end
