
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

package {
  ubuntu-desktop: ensure => present; # Convert base image into a desktop system
  #'dkms':         ensure => present; # For vbox guest additions.
  'git':          ensure => present;
}

ros::install { 'hydro': }

ros::user { 'ros': }

