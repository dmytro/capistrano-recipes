namespace :prerequisites do 

  namespace :install do 
    
    
    desc <<-HELP
Install sudo on the remote server.

Recipe will try to detect if sudo is installed on target server (which
sudo) and if not, install it. For the sudo installation it is assumed
that standard package manager is configured for the distro and is able
to access network.

Recipe uses 'su' command for installation and will ask for root
password.

HELP

    task :sudo do 

      installed = (capture("which sudo > /dev/null 2>&1 ; echo $?", shell: :bash).strip == '0')
      next if installed

      release = capture("\ls -1d /etc/*{release,version} 2> /dev/null || true ", shell: :bash)

      case release
      when /debian/
        surun "apt-get install sudo"
      when /redhat/
        surun "yum install sudo"
      end

    end
  end
end
