=begin rdoc

In case when environment has only one GW to access the internet, this
recipe can be used to setup HTTP proxy server and configure all other
hosts (clients here) to use proxy for internet connection.

In this case order is important since clients can not bootstrapped
unless proxy is setup and client is configured. Order of tasks is like
following:

Proxy server
-----------

- sudo install and configure
- bootstrap
- add epel repository
- install tinyproxy

After server setup finished can start with clients

Client
-----------
- configure http proxy

The rest:
- sudo install
- bootstrap
- ...


All this better done in setup task. Main `deploy.rb` should have
something like:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ruby
task :setup do
  top.http_proxy.server
  top.http_proxy.client
end
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=end


set_default :proxy_port, 8888

namespace :http_proxy do 

  desc <<EOF
Configure host as client of HTTP proxy"


EOF
  task :client, :except => {  :roles => 'proxy' } do
    set :proxy_host, find_servers(:roles => 'proxy').first # Should be only one proxy

    next if proxy_host.nil?

    set :client_hosts, find_servers - [proxy_host]

    template "http_proxy.sh.erb", "/tmp/http_proxy.sh"
    sudo "mv -f /tmp/http_proxy.sh /etc/profile.d/http_proxy.sh || true", shell: :bash 
  end

  task :disable do 
    sudo "rm -f  /etc/profile.d/http_proxy.sh || true", shell: :bash 
  end

  desc <<EOF
Bootstrap and configure host as HTTP proxy"


EOF
  task :server do
    set :only_hosts, find_servers(roles: :proxy)

    top.prerequisites.install.sudo
    top.prerequisites.configure.sudo
    top.chefsolo.deploy
    top.chefsolo.roles

    unset :only_hosts

    puts "################################## DONE PROXY ################################ "
  end


end

before 'deploy', 'http_proxy:client'
