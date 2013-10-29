namespace :setup do
  
  desc <<-DESC
Set hostname of the target host.

Recipe uses :hostname attribute from the server definition in
Capistrano. Hostname should be defined properly for all production
hosts - it is used for remote logging. Hostnames should be unique.

Supported OS: RHEL/CentOS (etc/sysconfig/network) and Debian/Ubuntu (/etc/hostname).

Note: This tested only on Linux, since in depends on format returned by Linux's ifconfig.

Source: #{path_to __FILE__}

DESC
  task :hostname do
    # Use actuall sudo here - since we'd running this before
    # bootstrapping without RVM, so rvmsudo is not there.
    temp_sudo = sudo
    set :sudo, "sudo"
    find_servers_for_task(current_task).each do |current_server|

      hostname = current_server.options[:hostname]
      next unless hostname

      run "hostname | grep ^#{hostname}$ > /dev/null || ( #{sudo} hostname #{hostname}; if [ test -d /etc/sysconfig ]; then (echo NETWORKING=yes; echo NETWORKING_IPV6=no; echo HOSTNAME=#{hostname}) | sudo tee /etc/sysconfig/network; else echo #{hostname} | sudo tee /etc/hostname; fi)", :hosts => [current_server.host], shell: :bash
      run "grep ' #{hostname}$' /etc/hosts || (IP=$(ifconfig | awk -F':' '/inet addr/&&!/127.0.0.1/{split($2,_,\" \");print _[1]}') && echo \"$IP #{hostname}\" | sudo tee -a /etc/hosts)", :hosts => [current_server.host], shell: :bash

    end # current_server
  end #: hostname

end

before "deploy:setup", "setup:hostname"
