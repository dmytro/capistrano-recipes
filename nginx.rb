set_default(:nginx_port, 80)
set_default(:nginx_error_pages, true)
set_default(:nginx_chrome_frame, true)
set_default(:domain_name, "#{application}")
set_default(:nginx_access_log, "#{shared_path}/log/nginx_#{application}_access.log")
set_default(:nginx_error_log, "#{shared_path}/log/nginx_#{application}_error.log")

namespace :nginx do

  # desc "Install latest stable release of nginx"
  # task :install, roles: :web do
  #   run "#{try_sudo} add-apt-repository ppa:nginx/stable"
  #   run "#{try_sudo} apt-get -y update"
  #   run "#{try_sudo} apt-get -y install nginx"
  # end
  # after "deploy:install", "nginx:install"

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

Source #{path_to __FILE__}

DESC
  task :setup, roles: [:app, :web], except: { no_release: true } do
    template "nginx.conf.erb", "/tmp/nginx_conf"
    run "#{try_sudo} mkdir -p #{shared_path}/config"
    run "#{try_sudo} cp /tmp/nginx_conf #{shared_path}/config/nginx.conf"
    sudo "mkdir -p /etc/nginx/sites-enabled/"
    sudo "mv /tmp/nginx_conf /etc/nginx/sites-enabled/#{application}"
    sudo "rm -f /etc/nginx/sites-enabled/default"
  end
  after "deploy:setup", "nginx:setup"

  %w[start stop].each do |command|
    desc "#{command} nginx"
    task command, roles: [:app, :web], except: { no_release: true }  do
      sudo "service nginx #{command}"
    end
    after "deploy:#{command}", "nginx:#{command}"
  end

  desc "Restart nginx"
  task :restart, roles: [:app, :web], except: { no_release: true } do
    sudo "service nginx restart"
  end

  desc <<-DESC
Ensure Apache is not running in case it is installed.

Source #{path_to __FILE__}
DESC
  task :apache_stop, roles: [:app, :web], except: { no_release: true }  do
    %w{ apache2 apache httpd }.each do |serv| # Different names for apache in varios distros
      sudo "service #{serv} stop || true"
    end
  end
end
