
include apt

$ros_version = "hydro"
$ros_package = "ros-${ros_version}-desktop-full"

# Needed for key adding
package { 'wget': ensure => installed }

apt::key { 'ros':
  key        => 'B01FA116',
  key_source => 'http://packages.ros.org/ros.key',
  notify => Exec['apt_update'],
}

apt::source { 'ros':
  location    => "http://packages.ros.org/ros/ubuntu",
  repos       => "main",
  key         => 'B01FA116',
  include_src => false,
  require     => Package['wget']
}

package {
  ubuntu-desktop:      ensure => present;
  $ros_package:        ensure => present, require => Apt::Source['ros'];
  'python-wstool':     ensure => present, require => Apt::Source['ros'];
  'python-rosinstall': ensure => present, require => Apt::Source['ros'];
  'git':               ensure => present;
}

exec {'rosdep-init':
    command => '/usr/bin/rosdep init',
    require => Package['ros-hydro-desktop-full'],
    creates => '/etc/ros/rosdep/sources.list.d/20-default.list';
}

group { 'ros':
  ensure => present
}

