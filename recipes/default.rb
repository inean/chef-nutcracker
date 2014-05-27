#
# Cookbook Name:: nutcracker
# Recipe:: default
#
# Copyright 2014, Vubeology LLC
#

include_recipe "apt"
include_recipe "build-essential"

bash "clone nutcracker" do
  user "vagrant"
  group "vagrant"
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
  user "vagrant"
  group "vagrant"
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
  user "vagrant"
  group "vagrant"
  cwd "#{node['nutcracker']['build_dir']}/twemproxy"
  code <<-EOH
  sudo make install > install.log 2>&1
  EOH
  not_if { ::File.exist?("#{node['nutcracker']['executable']}") }
end
