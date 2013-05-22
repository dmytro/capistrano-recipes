#
# Recipre to deploy Unicorn app server with Apache2
# Source: https://github.com/teambox/teambox/wiki/Installing-on-Ubuntu-using-Apache-and-Unicorn
# ------------------------------------------------------------------

set_default :apache_port,           80
set_default :apache_available_dir,  "/etc/httpd/sites-available"
set_default :web_domain,            "#{application}.com"
set_default :virtual_host,          "#{application}"
set_default :unicorn_port,          5000 # Note: apache is not able to listen on a socket.

namespace :apache do 
  namespace :unicorn do 

    desc <<-EOF

Create virtual host for Apache with Unicorn

Install required for Unicorn Apache modules, upload ERB Apache Virtual
host template and enable site for Apache application config file

Configuration
-------------

Change values accordingly to your host.

* set :apache_port,           80
* set :apache_available_dir,  "/etc/httpd/sites-available"
* set :web_domain,            "#{application}.com"
* set :virtual_host,          "#{application}"

EOF
    task :configure do
      json = "/tmp/apache_unicorn_modules.json"
      template "apache_unicorn_virtual_host.conf.erb", "#{apache_available_dir}/#{virtual_host}"
      run "#{try_sudo} a2ensite #{virtual_host}"

      template "apache_unicorn_modules.json.erb", json
      run "#{chef_solo_command} #{json} && rm -f #{json}"
    end

  end

end


