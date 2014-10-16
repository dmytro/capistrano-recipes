# -*- coding: utf-8 -*-

namespace :chefsolo do
  namespace :databag do

    # @param [String] name name of the databag (directory)
    # @param [Hash] data
    # def write_databag name, data
    # end


    desc <<-DESC
[internal] Build Chef databag from Capistrano configuration.

Expose Capistrano configuration to Chhef as databag. Create and save
data_bag to all remote servers with current Capistrano
configuration. Databag is :capistrano, item :config.

Actuall contents of the databag depends on the configuration, all
Capistrano variables exported as hash.

See also `cap -e configuration_bag`

Source #{path_to __FILE__}
DESC
    task :cap do
      top.configuration_bag
    end

  end
end

desc <<-DESC
[internal] Build databag from Capistrano configuration.

This needs to be top level recipe, variables are not accessible in the
namespaced scope.

Source #{path_to __FILE__}
DESC
task :configuration_bag do
  vars = {}
  @variables.each { |k,v| vars[k] = v unless v.class == Proc }

  dir = "#{local_chef_cache_dir}/data_bags/capistrano"
  FileUtils.mkdir_p dir
  File.open("#{dir}/config.json", "w") do |file|
    file << vars.merge({ "id" => "config"}).to_json
    file.close
  end

end
