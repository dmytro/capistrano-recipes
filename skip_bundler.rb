#
# For environment that don't need bundler, simply create empty task for bundle install
#
namespace :bundle do
  task :install do
    puts "* * * Skip bundler * * * "
  end
end
