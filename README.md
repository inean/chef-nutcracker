nutcracker Chef Cookbook
========================

This cookbook installs [twitter/twemproxy](https://github.com/twitter/twemproxy) (nutcracker).

It just downloads source from Github, compiles and installs.  You can set up custom configure flags
or compiler environment variables via attributes if needed.

    NOTE: The configuration of this has changed significantly from version 1.0 to version 1.1.
    We are no longer using data_bags to configure instances, we're using attributes now.

## Installation

Add a submodule dependency to your project, I'm assuming here that chef/cookbooks/ is the sub-directory
where you want your cookbook dependencies installed.  Whatever path you choose to check it out to, make
sure that is in your cookbook search path.

```bash
$ git submodule add https://github.com/vube/chef-nutcracker chef/cookbooks/chef-nutcracker
```

### In your metadata.rb
```ruby
depends "chef-nutcracker"
```

### In your recipe.rb
```ruby
include_recipe "chef-nutcracker"
```

## Configuration

To configure this you must configure the `node['nutcracker']['instances']` attribute.

### Examples

#### Single nutcracker instance

```ruby
default['nutcracker']['instances']['my_instance'] = {
    'port' => 22122,
    'servers' => ['localhost:6375:1', 'localhost:6379:1']
}
```

#### Single nutcracker instance using memcache

```ruby
default['nutcracker']['instances']['my_instance'] = {
    'port' => 22122,
    'redis' => false,
    'servers' => ['localhost:6375:1', 'localhost:6379:1']
}
```

#### Multiple nutcracker instances on different ports

```ruby
default['nutcracker']['instances']['my_instance_1'] = {
    'port' => 22122,
    'servers' => ['localhost:6375:1', 'localhost:6379:1']
}
default['nutcracker']['instances']['my_instance_2'] = {
    'port' => 33233,
    'servers' => ['localhost:7486:1', 'localhost:7480:1']
}
```
