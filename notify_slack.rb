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
  (fetch(:chef_environment) == "testing") ? "dev_test" : "#dev-deploy"
end


namespace :notify do
  namespace :deploy do
    task :start do
      msg  = "Yes, my lord.\n Start deploying \`#{fetch(:branch)}\` @ \`#{fetch(:application)}\` to \`#{fetch(:chef_environment)}\` by order of \`#{fetch(:user_name)}\`."
      _send_message(msg, _slack_channel)
    end
 
    task :finish do
      msg  = "[\`#{fetch(:application)}\`] Deployment complete, sir! :thumbsup:\n"
      _send_message(msg, _slack_channel)
    end
  end
 
  namespace :rollback do
    task :start do
      msg  = "[\`#{fetch(:application)}\`] Yes, my lord. Rollback has started.\nCurrent Revision is \`#{fetch(:latest_revision)}\`"
      _send_message(msg, _slack_channel)
    end
 
    task :finish do
      msg  = "[\`#{fetch(:application)}\`] Rollback complete, sir! :ok_woman:\nCurrent revision is \`#{fetch(:current_revision)}\`"
      _send_message(msg, _slack_channel)
    end
  end
end
 
before 'chefsolo:setup', 'notify:deploy:start'
after 'chefsolo:cleanup', 'notify:deploy:finish'
before 'deploy:rollback', 'notify:rollback:start'
after 'deploy:rollback:cleanup', 'notify:rollback:finish'
