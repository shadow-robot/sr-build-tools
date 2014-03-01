
Exec {
  path => [
    '/usr/local/bin',
    '/opt/local/bin',
    '/usr/bin',
    '/usr/sbin',
    '/bin',
    '/sbin',
    '/opt/vagrant_ruby/bin/'],
  logoutput => true,
}

include ros

# The ROS base image.
node 'ros-hydro-desktop-precise64.box.local' {
  package {
    ubuntu-desktop: ensure => present; # Convert base image into a desktop system
    #'dkms':         ensure => present; # For vbox guest additions.
    'git':          ensure => present;
  }

  # Allow guest additions to be installed from the iso.
  package {
    "linux-headers-${kernelrelease}" : ensure => installed;
    build-essential                  : ensure => installed;
    dkms                             : ensure => installed;
  }

  ros::install { 'hydro': }

  ros::user { 'ros': }
}

node 'hand-hydro-precise64.box.local' {
  notify { 'hello world!': }
}
