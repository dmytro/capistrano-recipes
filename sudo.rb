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

Currently supported Debian and RedHat type distros (i.e. apt-get and
yum installs).

HELP

    task :sudo do 

      installed = test_command "which sudo"
      next if installed

      release = capture("\ls -1d /etc/*{release,version} 2> /dev/null || true ", shell: :bash)

      puts <<-MSG
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SUDO is not installed. 

Please type root password at the prompt below, 
we will try to install it.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

MSG

      case release
      when /debian/
        surun "apt-get install -y sudo"
      when /redhat/
        surun "yum install -y sudo"
      end

    end
  end
end

before "chefsolo:deploy", "prerequisites:install:sudo"

# TODO: fix it - runs twice
# before "deploy", "prerequisites:install:sudo" # If chef-solo deploy is
#                                               # not used, still make
#                                               # sure sudo is installed
