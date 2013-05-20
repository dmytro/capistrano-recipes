namespace :logs do 

  desc "Tail Unicorn logs"
  task :tail do 
    run "tail -n 100 apps/#{application}/current/log/unicorn*"
  end

  desc "Clear all Unicorn logs"
  task :clear do
    run "for i in apps/#{application}/current/log/unicorn*; do cat /dev/null > $i; done"
  end
end
