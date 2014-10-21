#
# @author Dmytro Kovalov, dmytro.kovalov@gmail.com
#
namespace :chefsolo do
  task :exit_on_request do
    if fetch(:only_infra, false)
      logger.info "********************** ONLY INFRA specified, Infra deployed. Stopping on user request. **********************"
      exit
    end
  end
end
