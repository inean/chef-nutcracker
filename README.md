nutcracker Chef Cookbook
========================

This cookbook installs [twitter/twemproxy](https://github.com/twitter/twemproxy) (nutcracker).

It just downloads source from Github, compiles and installs.  You can set up custom configure flags
or compiler environment variables via attributes if needed.

## Installation

Add a submodule dependency to your project, I'm assuming here that chef/cookbooks/ is the sub-directory
where you want your cookbook dependencies installed.  Whatever path you choose to check it out to, make
sure that is in your cookbook search path.

```bash
$ git submodule add https://github.com/vube/chef-nutcracher chef/cookbooks/chef-nutcracker
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

To configure this you must include a nutcracker/instances.json data_bag in your main chef recipe.

### Examples

#### Single nutcracker instance

```json
{
	"id": "instances",
	"instances": [{
		"id": "my_instance_1",
		"port": 22122,
		"servers": ["localhost:6375:1", "localhost:6379:1"]
	}]
}
```

#### Multiple nutcracker instances on different ports

```json
{
	"id": "instances",
	"instances": [{
		"id": "my_instance_1",
		"port": 22122,
		"servers": ["localhost:6375:1", "localhost:6379:1"]
	},{
		"id": "my_instance_2",
		"port": 33233,
		"servers": ["localhost:7486:1", "localhost:7480:1"]
	}]
}
```
