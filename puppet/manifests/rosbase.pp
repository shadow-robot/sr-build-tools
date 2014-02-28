
include ros

package {
  ubuntu-desktop: ensure => present; # Convert base image into a desktop system
  #'dkms':         ensure => present; # For vbox guest additions.
  'git':          ensure => present;
}

ros::install { 'hydro': }

ros::user { 'ros': }

