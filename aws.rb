#
# @author Dmytro Kovalov, dmytro.kovalov@gmail.com
#
require 'fog'

#
# Will use ~/.fog file
#
set :aws_connection, Fog::Compute.new({ provider:  'AWS' })

def original(name)
  orig  = find_servers(hosts: name).first
  aws_connection.servers.all('private-ip-address' => orig.host).first
end

namespace :aws do
  namespace :ec2 do

    desc <<-DESC
    Clone existing server with new AIM

  Options
  -------------

*  set `-s name=<IP or hostname>` host to clone
*  set `-s amiid=<AMI ID>` new AMI to use for the clone


Source File #{path_to __FILE__}

DESC
    task :clone_server  do

      unless fetch(:name, false)
        puts "Please provide hosname or IP of existing server\n"
        find_servers.each do |server|
          puts "#{ server.host }: #{role_names_for_host(server).join(', ')}"
        end
        abort
      end

      amiid = fetch(:amiid, nil)
      orig  = original fetch(:name)
      clone = orig.inspect

      clone = aws_connection.servers.create(
        vpc_id:             orig.vpc_id,
        image_id:           amiid,
        availability_zone:  orig.availability_zone,
        subnet_id:          orig.subnet_id,
        security_group_ids: orig.security_group_ids,
        flavor_id:          orig.flavor_id,
        kernel_id:          orig.kernel_id,
        key_name:           orig.key_name,
        placement: {
          availability_zone: orig.availability_zone,
        },
        network_interfaces: [{
          vpc_id:             orig.vpc_id,
          subnet_id:           orig.subnet_id,
          device_index:       0,
          associate_public_ip_address: false
        }]
      )
      clone.wait_for { print "."; ready? }

      puts "Public IP Address: #{clone.public_ip_address}"
      puts "Private IP Address: #{clone.private_ip_address}"

    end

  end
end
