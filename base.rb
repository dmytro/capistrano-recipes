def template(from, to)
  erb = File.read(File.expand_path("../templates/#{from}", __FILE__))
  put ERB.new(erb,0,'<>%-').result(binding), to
end

def set_default(name, *args, &block)
  set(name, *args, &block) unless exists?(name)
end

# Runs +command+ as root invoking the command with su -c
# and handling the root password prompt.
#
#   surun "/etc/init.d/apache reload"
#   # Executes
#   # su - -c '/etc/init.d/apache reload'
#
def surun(command)
  password = Capistrano::CLI.password_prompt("root password: ")
  
  run("su - -c '#{command}'", :shell => :bash) do |channel, stream, output|
    channel.send_data("#{password}n") if output
  end
end


set_default :recipe_base, "lib"
##
# Load additional recipes from file. Extension for the DSL.
#
def recipe name, local = false
  path = local ? "local_recipes" : "recipes"
  load File.expand_path("#{recipe_base}/#{path}/#{name.to_s}.rb")
end
