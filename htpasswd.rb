namespace :setup do 
  
  desc <<-DESC
Creates and installs htpasswd file for basic auth.

User data are read from :users databag. 

Configuration
-------------

- :htpasswd_file - - :htpasswd_file - PATH to basic auth htpasswd file
  can be used both by Apache and Nginx.

- :basic_auth_users - list of :users databag ID's (Array)

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
recipe: :htpasswd
set :enable_basic_auth, true
set :basic_auth_users, [:jon, :jim]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- databag format:

  - "id", "name"and either "htpasswd" or "crypted_htpasswd" are
    required.

  - Either plain text of crypted password can be specified
    crypted_htpasswd takes precedence before plain text.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    "id"        : "jon",
    "name"      : "jon",
    "comment"   : "Basic Auth user Jon Doe",
    "home"      : "",
    "htpasswd"  : "plaintext_secret"
    "crypted_htpasswd"  : "$apr1$Wzfn/GtZ$Dc3CxM(llz0MR5YZhG9FDQD/"
}
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


Source #{ path_to __FILE__}

DESC
  task :htpasswd, roles: :web do
    unless fetch(:enable_basic_auth, false)
      logger.info "Basic auth usage not configured"
    else
      run "cat /dev/null >  #{htpasswd_file}"
      
      basic_auth_users.each do |user|
        user = get_data_bag :users, user
        cmd = if user.has_key? "crypted_htpasswd"
                "echo #{user['name']}:#{user['crypted_htpasswd']} >> #{htpasswd_file}"
              else
                "htpasswd -mb #{htpasswd_file} #{user['name']} #{user['htpasswd']}"
              end
        run cmd
      end    
    end
  end
end
