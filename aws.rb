#
# @author Dmytro Kovalov, dmytro.kovalov@gmail.com
#
namespace :aws do
  require 'fog'

  def check_instance_name
  unless fetch(:name, false)
    puts "Please provide hosname or IP of existing server\n"
    find_servers.each do |server|
      puts "#{ server.host }: #{role_names_for_host(server).join(', ')}"
    end
    abort
  end
  set :original_ec2_instance_name, fetch(:name)
  set :original_capistrano_server, find_servers(name: original_ec2_instance_name).first
  end

  def connection
    #
    # This will use ~/.fog file, fails if file is not present
    #
    set :aws_connection, Fog::Compute.new({ provider:  'AWS' })
    aws_connection
  end


  namespace :ec2 do

    def ec2_original
      @org ||= connection.servers.all('private-ip-address' => original_capistrano_server.host).first
    end

    desc <<-DESC
    Clone existing server with new AIM.

Recipe coonects to AWS API, fetches information of the existing server
and creates a new one from provided AMI using information of the
original server.

New server will have following identical to the original:

- EC2 instance type
- VPC
- subnet
- availablility zone
- security groups
- SSH key pair


  Options
  -------------

*  set `-s name=<IP or hostname>` host to clone (required)
*  set `-s amiid=<AMI ID>` new AMI to use for the clone.
   If not provided as CLI option should be set in deploy recipe as `amiid` variable.

  Configuration
  -------------

This recipe uses ~/.fog file for authenticating with AWS. If file is
absent it will fail. Example of ~/.fog file:

---
:default:
  :aws_access_key_id: "AWS_ACCESS_KEY_ID"
  :aws_secret_access_key: "AWS_SECRET_ACCESS_KEY"
  :region: ap-northeast-1


Source File #{path_to __FILE__}

DESC
    task :clone_server  do
      check_instance_name

      amiid      = fetch(:amiid, nil)
      orig       = ec2_original
      clone_name = "Copy of #{orig.tags['Name'].nil? ? fetch(:name) : orig.tags['Name']}"
      clone      = aws_connection.servers.create(
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
        }],
        tags: orig.tags.merge('Name' => clone_name)
      )
      clone.wait_for { print "."; ready? }

      puts ""
      puts "Public  IP Address: #{clone.public_ip_address}"
      puts "Private IP Address: #{clone.private_ip_address}"

    end

    desc <<-DESC

Display configuration parameters of EC2 instance.

  Options
  -------------

*  set `-s name=<IP or hostname>` host to inspect (required).


Source File #{path_to __FILE__}

DESC
    task :show do
      check_instance_name

      server = original_capistrano_server
      puts <<-PRINT
********************************************
Capistrano configuration
********************************************
Roles: #{role_names_for_host(server).join(' ')}
#{server.to_yaml}

********************************************
AWS EC2 configuration
********************************************
#{ec2_original.attributes.to_yaml}
PRINT
    end

    namespace :ami do

      def ami_name
        "#{ec2_original.tags['Name'].nil? ?
            ec2_original.id :
            ec2_original.tags['Name']}-#{Time.now.strftime("%Y%m%d%H%M%S")}"
          .gsub(/\s/, "_")

      end

      desc "List existing AMI images (only owned by me)."
      task :list do
        format = "%-15s%-30s%s\n"
        imgs = connection.images.all('Owner' => 'self')
        printf format, 'ID', 'Name', 'Description'
        imgs.each do |i|
          printf format, i.id, i.name, i.description
        end
      end

      desc <<-DESC
Create AMI image from the instance.

  Options
  -------------

*  set `-s name=<IP or hostname>` original instance (required).
*  set `-s aminame=<NEW_AMI_NAME>` to set the name.


Source File #{path_to __FILE__}
DESC

      task :create do
        check_instance_name


        orig_ami = connection.images.all("image-id" => ec2_original.image_id).first
        response = connection.create_image(
          ec2_original.id,
          ami_name,
          "Created from #{ ec2_original.id }, #{orig_ami.name} "
        )

        img = connection.images.all("image-id" => response.body["imageId"]).first

        img.wait_for { print "."; ready? }
        puts img.attributes.to_yaml
      end
    end
  end
end
