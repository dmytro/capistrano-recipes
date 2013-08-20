set_default :proxy_port, 8888

namespace :http_proxy do 

  desc "Configure host as client of HTTP proxy"
  task :client, :except => {  :role => 'proxy' } do
    set :proxy_host, find_servers(:role => 'proxy').first # Should be only one proxy
    template "http_proxy.sh.erb", "/etc/profile.d/http_proxy.sh"
  end
end

before 'deploy', 'http_proxy:client'
