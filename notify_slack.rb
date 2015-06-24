require 'uri'
require 'net/http'
require 'json'

set :user_name, `whoami`.chomp
 
def _send_message(message, channel)
  payload = {
    :text => message,
    :channel => channel,
    :username => 'Capiche Kun',
    :icon_url => '',
    :icon_emoji => ':capiche:',
  }
 
  uri = URI.parse(fetch(:webhook_url))
 
  response = nil
 
  request = Net::HTTP::Post.new(uri.request_uri)
  request.set_form_data({ :payload => JSON.generate( payload ) })
 
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
 
  http.start do |h|
    response = h.request(request)
  end
 
  response
end

def _slack_channel
  (fetch(:stage) == "localhost") ? "dev_test" : "#dev-deploy"
end


namespace :slack do
  namespace :deploy do
    task :start do

      msg = "<!channel>\n Hey guys, I just started deployment by order of my commander.\n"
      msg << "\`\`\`\n"
      if fetch(:only_infra, false)
        msg << "Application  : infrastructure}\n"
      elsif fetch(:with_infra, false)
        msg << "Application  : #{fetch(:application)}, infrastructure\n"
      else
        msg << "Application  : #{fetch(:application)}\n"
      end
      msg << "Branch/Tag   : #{fetch(:branch)}\n"
      msg << "Environment  : #{fetch(:stage)}\n"
      msg << "My commander : #{fetch(:user_name)}\n"
      msg << "\`\`\`\n"

      logger.info msg
      _send_message(msg, _slack_channel)
    end
 
    task :finish do
      msg  = "[\`#{fetch(:application)}\`] Deployment complete, sir! :thumbsup:\n"
      logger.info msg
      _send_message(msg, _slack_channel)
    end
  end
 
  namespace :rollback do
    task :start do
      msg  = "[\`#{fetch(:application)}\`] Yes, my master. Rollback has started.\nCurrent Revision is \`#{fetch(:latest_revision)}\`"
      logger.info msg
      _send_message(msg, _slack_channel)
    end
 
    task :finish do
      msg  = "[\`#{fetch(:application)}\`] Rollback complete, sir! :ok_woman:\nCurrent revision is \`#{fetch(:current_revision)}\`"
      logger.info msg
      _send_message(msg, _slack_channel)
    end
  end
end
 
before 'deploy', 'slack:deploy:start'
after 'deploy:cleanup', 'slack:deploy:finish'
before 'deploy:rollback', 'slack:rollback:start'
after 'deploy:rollback:cleanup', 'slack:rollback:finish'
