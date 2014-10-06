#
# Cookbook Name:: nutcracker
# Recipe:: instance
#
# Copyright 2014, Vubeology LLC
#

# Initialize any server instances on the VM based on the data_bag config

node['nutcracker']["instances"].each do |id, instance|

  # instance['servers'] is a string template.
  #
  # The special sequence !{eval_code} will evaluate the Ruby code 'eval_code'
  # and its result will be replaced in the string.  It's like #{eval_code}
  # in normal Ruby strings, but it's a post-process value of that.
  #
  # Example: server = "foo!{true?'=':'!='}bar"
  # Result: server = "foo=bar"

  servers = []
  instance['servers'].each do |s|
    while m = s.match(/(.*)\!\{([^\}]+)\}(.*)/) do
      before = m[1]
      code = m[2]
      after = m[3]
      if code.to_s == ''
        raise "Code is an empty string! m=#{m.inspect}"
      end
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
              :auto_eject_hosts => instance['auto_eject_hosts'].nil? ? node['nutcracker']['default'][:auto_eject_hosts] : instance['auto_eject_hosts'],
              :redis => instance['redis'].nil? ? node['nutcracker']['default'][:redis] : instance['redis']
    notifies :restart, "service[nutcracker_#{instance['port']}]"
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
              :stats_port => instance['stats_port'].nil? ? node['nutcracker']['default'][:stats_port] : instance['stats_port'],
              :executable => node['nutcracker']['executable'],
              :username => node['nutcracker']['username'],
              :usergroup => node['nutcracker']['user_group']
    notifies :restart, "service[nutcracker_#{instance['port']}]"
  end

  # Start nutcracker and enable it at future system boot
  service "nutcracker_#{instance['port']}" do
    supports :restart => true, :status => true, :configtest => true
    action [:start, :enable]
  end

end
