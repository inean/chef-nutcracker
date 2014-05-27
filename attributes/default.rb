
# build_dir: Which directory to clone nutcracker source into and build it
default['nutcracker']['build_dir'] = "/home/vagrant/build"

# configure_flags: Optional flags to pass to nutcracker's configure
# See https://github.com/twitter/twemproxy for details
default['nutcracker']['configure_flags'] = ""

# CFLAGS: Optional CFLAGS environment variable for configure
# See https://github.com/twitter/twemproxy for details
default['nutcracker']['CFLAGS'] = ""

# executable: The executable file that is the result of all this.
# This doesn't determine where to put it, it just lets us test if we
# have successfully completed the process.
default['nutcracker']['executable'] = "/usr/local/sbin/nutcracker"
