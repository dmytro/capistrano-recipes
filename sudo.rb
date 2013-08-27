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

      cmd = "which sudo" << " > /dev/null 2>&1 ; echo $?"
      installed = (capture(cmd, shell: :bash, pty: true).strip.to_i == 0)

      unless installed
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

  namespace :configure do 
    
    desc "Check that necessary config exists for sudo and create it if not"
    task :sudo do 

      cmd = "sudo -l -n" << " > /dev/null 2>&1 ; echo $?"
      configured = (capture(cmd, shell: :bash, pty: true).strip.to_i == 0)

      unless configured
        
        puts <<-MSG
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SUDO is not cofigured for user '#{user}'

Please type root password at the prompt below, 
we will try to configure it.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

MSG

      cmd = "ls -ld /etc/sudoers.d" << " > /dev/null 2>&1 ; echo $?"
      dir_exist = (capture(cmd, shell: :bash, pty: true).strip.to_i == 0)
        
        tmp = capture("mktemp", shell: :bash).strip
        
        if dir_exist
          surun "echo \"#{user}   ALL=(ALL) NOPASSWD: ALL\" >  /etc/sudoers.d/deploy_user_#{user}"
        else
          surun "cat /etc/sudoers > #{tmp}"
          
          run "echo \"#{user}   ALL=(ALL) NOPASSWD: ALL\" >> #{tmp}", shell: :bash
          
          ok = test_command "visudo -c -f #{tmp}" # Check syntax
          abort "ATTENTION: Syntax check of sudoers file failed. Please investigate before continuing." unless ok
          
          surun "cat #{tmp} > /etc/sudoers"
          
        end
        run "rm -f #{tmp}", shell: :bash
      end
    end
  end
end


before "chefsolo:deploy", "prerequisites:install:sudo"
after "prerequisites:install:sudo", "prerequisites:configure:sudo"

# TODO: fix it - runs twice
# before "deploy", "prerequisites:install:sudo" # If chef-solo deploy is
#                                               # not used, still make
#                                               # sure sudo is installed
