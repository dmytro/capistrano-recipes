#
# Adds simple crontab entry on servers, having role :crontab.
#
namespace :crontab do
  #
  #  Full crontab entry with times and full command. As defined by crontab(5).
  #
  set_default(:crontab_entry, " * * * * * true")
  #
  # 'Label' for the crontab entry. Should be something uniq, used for crontab editing.
  #
  set_default(:crontab_entry_name, :example_crontab)
  #
  # Envrinment for the command execution. Hash: {SHELL: "/bin/bash", MAIL: "dmytro@example.com"}
  #
  set_default(:crontab_entry_environment, nil)

  desc <<-DESC
  Adds simple crontab entry on servers, having role :crontab.

This is very simple cron add/delete function. For anything more
advanced you should use tools designed specifically for it, like
Whenever gem or similar.

Configuration:

Set following variables:

- :crontab_entry
- :crontab_entry_name
- :crontab_entry_envvironment

Source #{path_to __FILE__}
DESC
  task :add,  :roles => :crontab, :except => { :no_release => true }  do
    tmpname = "/tmp/#{crontab_entry_name}-crontab.#{Time.now.strftime('%s')}"
    tmpenv  = "/tmp/#{crontab_entry_name}-env.#{Time.now.strftime('%s')}"
    run "(crontab -l || echo '') | sed '/# #{crontab_entry_name} start/,/# #{crontab_entry_name} end/d' > #{tmpname}"
    run "echo '# #{crontab_entry_name} start' >> #{tmpname }"
    if crontab_entry_environment
      put(crontab_entry_environment.map{ |key, value| "#{key.to_s}=#{value.to_s}" }.join("\n"),  "#{tmpenv}")
      run "cat #{tmpenv} >> #{tmpname} && rm -f #{tmpenv}"
      run "echo >> #{tmpname}"
    end
    run "echo '#{crontab_entry}' >> #{tmpname}"
    run "echo '# #{crontab_entry_name} end' >> #{tmpname }"
    run "crontab #{tmpname} && rm #{ tmpname }"
  end

  desc <<-DESC
  Remove crontab entry on servers, created by crontab:add task.

Source #{path_to __FILE__}
DESC

  task :remove do
    run "(crontab -l || echo '') | sed '/# #{crontab_entry_name} start/,/# #{crontab_entry_name} end/}d' | crontab - "
  end
end
