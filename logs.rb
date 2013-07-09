namespace :logs do 

  desc "tail production log files" 
  task :tail, :roles => :app do
    trap("INT") { puts 'Interupted'; exit 0; }
    run "tail -f #{shared_path}/log/production.log" do |channel, stream, data|
      puts  # for an extra line break before the host name
      puts "#{channel[:host]}: #{data}" 
      break if stream == :err
    end
  end

  desc "Clear all production logs"
  task :clear do
    run "cat /dev/null > #{shared_path}/log/production.log"
  end
end
