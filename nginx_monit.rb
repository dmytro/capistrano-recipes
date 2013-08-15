namespace :nginx do

  desc <<-EOF
Restart Nginx with monit

When Monit installed include this recipe as `recipe :nginx_monit` to
use monit for restarting Nginx.

EOF

  task :restart, :roles => :app do
    run "#{sudo} monit restart nginx"
  end
end
