set_default(:nginx_port, 80)
set_default(:nginx_error_pages, true)
set_default(:nginx_chrome_frame, true)
set_default(:domain_name, "#{application}")

namespace :nginx do

  # desc "Install latest stable release of nginx"
  # task :install, roles: :web do
  #   run "#{try_sudo} add-apt-repository ppa:nginx/stable"
  #   run "#{try_sudo} apt-get -y update"
  #   run "#{try_sudo} apt-get -y install nginx"
  # end
  # after "deploy:install", "nginx:install"

  desc "Setup nginx configuration for this application"
  task :setup, roles: :web do
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
    task command, roles: :web do
      sudo "service nginx #{command}"
    end
    after "deploy:#{command}", "nginx:#{command}"
  end

  desc "Restart nginx"
  task :restart, roles: :web do
    sudo "service nginx restart"
  end

  desc "Ensure Apache is not running in case it is installed"
  task :apache_stop, roles: :web do
    %w{ apache2 apache httpd }.each do |serv| # Different names for apache in varios distros
      sudo "service #{serv} stop || true"
    end
  end
end
