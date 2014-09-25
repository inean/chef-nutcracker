#
# Cookbook Name:: nutcracker
# Recipe:: default
#
# Copyright 2014, Vubeology LLC
#

include_recipe "apt"
include_recipe "build-essential"

# libtool is required to compile nutcracker
package "libtool"

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

# Now configure instances, if any
include_recipe "chef-nutcracker::instance"
