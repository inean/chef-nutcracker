#
# Cookbook Name:: nutcracker
# Recipe:: instance
#
# Copyright 2014, Vubeology LLC
#

# Initialize any server instances on the VM based on the data_bag config

instances = { "instances" => [] }
begin
  instances = data_bag_item(node["nutcracker"]["data_bag_name"], "instances")
rescue
  Chef::Log.info "No nutcracker instances specified in #{node["nutcracker"]["data_bag_name"]} data_bag"
end

instances["instances"].each do |instance|

  # Install the instance config
  template "/etc/nutcracker/nutcracker_#{instance['port']}.yml" do
    source "nutcracker.yml.erb"
    action :create_if_missing
    owner node['nutcracker']['username']
    group node['nutcracker']['user_group']
    mode 0664
    variables :id => instance['id'],
              :port => instance['port'],
              :servers => instance['servers'],
              :redis => instance['redis'].nil? ? true : instance['redis']
  end

  # Install the instance init.d startup script
  # Install the instance config
  template "/etc/init.d/nutcracker_#{instance['port']}" do
    source "nutcracker.sh.erb"
    action :create_if_missing
    owner "root"
    group "root"
    mode 0755
    variables :id => instance['id'],
              :port => instance['port'],
              :servers => instance['servers'],
              :executable => node['nutcracker']['executable'],
              :username => node['nutcracker']['username'],
              :usergroup => node['nutcracker']['user_group']
  end

  # Make nutcracker start when the VM boots
  execute "update-rc.d nutcracker_#{instance['port']}" do
    command "sudo update-rc.d nutcracker_#{instance['port']} defaults > /tmp/nutcracker_#{instance['port']}.update-rc.d_log 2>&1"
  end

  # Start nutcracker now if it is not already running
  execute "start nutcracker_#{instance['port']}" do
    command "sudo /etc/init.d/nutcracker_#{instance['port']} start > /tmp/nutcracker_#{instance['port']}.startup_log 2>&1"
    # But don't start it if it's already running
    not_if "ps auxgww | grep -v grep | grep nutcracker_#{instance['port']}"
  end

end
