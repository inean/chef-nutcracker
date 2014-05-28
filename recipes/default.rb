#
# Cookbook Name:: nutcracker
# Recipe:: default
#
# Copyright 2014, Vubeology LLC
#

include_recipe "apt"
include_recipe "build-essential"

bash "clone nutcracker" do
  code <<-EOH
  if [ ! -d "#{node['nutcracker']['build_dir']}" ]; then
    cd "`dirname #{node['nutcracker']['build_dir']}`" || exit 1
    mkdir "`basename #{node['nutcracker']['build_dir']}`" || exit 2
  fi
  cd "#{node['nutcracker']['build_dir']}" || exit 6
  git clone https://github.com/twitter/twemproxy || exit 9
  EOH
  not_if { ::File.exist?("#{node['nutcracker']['executable']}") || ::File.exist?("#{node['nutcracker']['build_dir']}/twemproxy") }
end

bash "compile nutcracker" do
  cwd "#{node['nutcracker']['build_dir']}/twemproxy"
  code <<-EOH
  autoreconf -fvi || exit 3
  ./configure #{node['nutcracker']['configure_flags']} || exit 5
  make clean all || exit 9
  EOH
  environment 'CFLAGS' => node['nutcracker']['CFLAGS']
  not_if { ::File.exist?("#{node['nutcracker']['executable']}") || ::File.exist?("#{node['nutcracker']['build_dir']}/twemproxy/src/nutcracker") }
end

bash "install nutcracker" do
  cwd "#{node['nutcracker']['build_dir']}/twemproxy"
  code <<-EOH
  sudo make install > install.log 2>&1
  EOH
  not_if { ::File.exist?("#{node['nutcracker']['executable']}") }
end

bash "create nutcracker group" do
  code <<-EOH
  sudo addgroup --system "#{node['nutcracker']['user_group']}"
  EOH
  # But don't do this if the user group already exists
  not_if "grep '#{node['nutcracker']['user_group']}' /etc/group"
end

# Create a nutcracker user if necessary
bash "create nutcracker user" do
  code <<-EOH
  sudo adduser --system --no-create-home --ingroup "#{node['nutcracker']['user_group']}" "#{node['nutcracker']['username']}"
  EOH
  # But don't do this if the username already exists
  not_if "id '#{node['nutcracker']['username']}'"
end

# Create directories and give nutcracker user write permissions in them
%w[/etc/nutcracker /var/log/nutcracker /var/run/nutcracker].each do |path|
  directory path do
    owner node['nutcracker']['username']
    group node['nutcracker']['user_group']
    mode 0775
    action :create
  end
end

# Initialize nutcracker data bag
nutcracker_data = []
begin
  nutcracker_data = data_bag(node["nutcracker"]["data_bag_name"])
rescue
  Chef::Log.warn "Failed to load #{node["nutcracker"]["data_bag_name"]} data_bag"
end

# Initialize any server instances on the VM based on the data_bag config

begin
  instances = data_bag_item(node["nutcracker"]["data_bag_name"], "instances")
rescue
  Chef::Log.info "No nutcracker instances specified in #{node["nutcracker"]["data_bag_name"]} data_bag"
  instances = { "instances" => [] }
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
              :servers => instance['servers']
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
