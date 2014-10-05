#
# Cookbook Name:: nutcracker
# Recipe:: instance
#
# Copyright 2014, Vubeology LLC
#

# Initialize any server instances on the VM based on the data_bag config

node['nutcracker']["instances"].each do |id, instance|

  servers = []
  instance['servers'].each do |s|
    while m = s.match(/(.*)\!\{([^\}]+)\}(.*)/) do
      before = m[0]
      code = m[1]
      after = m[2]
      Chef::Log.debug("nutcracker server info eval: #{code} from #{s}")
      result = Kernel.eval(code)
      s = "#{before}#{result}#{after}"
      Chef::Log.debug("nutcracker server info is now #{s}")
    end
    servers << s
  end

  # Install the instance config
  template "/etc/nutcracker/nutcracker_#{instance['port']}.yml" do
    source "nutcracker.yml.erb"
    action :create
    owner node['nutcracker']['username']
    group node['nutcracker']['user_group']
    mode 0664
    variables :id => id,
              :port => instance['port'],
              :servers => servers,
              :redis => instance['redis'].nil? ? true : instance['redis']
  end

  # Install the instance init.d startup script
  # Install the instance config
  template "/etc/init.d/nutcracker_#{instance['port']}" do
    source "nutcracker.sh.erb"
    action :create
    owner "root"
    group "root"
    mode 0755
    variables :id => id,
              :port => instance['port'],
              :servers => instance['servers'],
              :executable => node['nutcracker']['executable'],
              :username => node['nutcracker']['username'],
              :usergroup => node['nutcracker']['user_group']
  end

  # Make nutcracker start when the VM boots
  execute "update-rc.d nutcracker_#{instance['port']}" do
    command "sudo update-rc.d nutcracker_#{instance['port']} defaults"
    # Don't run update-rc.d if we already have start/stop scripts linked,
    # it doesn't do anything then anyway.
    not_if "ls /etc/rc*.d | grep '^S[[:digit:]]*nutcracker_#{instance['port']}$' > /dev/null"
  end

  # Start nutcracker now if it is not already running
  execute "start nutcracker_#{instance['port']}" do
    command "sudo /etc/init.d/nutcracker_#{instance['port']} start"
    # But don't start it if it's already running
    not_if "ps auxgww | grep -v grep | grep nutcracker_#{instance['port']} > /dev/null"
  end

end
