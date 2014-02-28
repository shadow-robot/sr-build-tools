# Definition: ros::install
#
# This resource installs versions of ros.
#
# Parameters:
# - The $ros_release (e.g. 'hydro') to install.
#
# Actions:
# - Adds ros apt key.
# - Adds ros repos to apt.
# - Activates restricted, universe, multiverse
# - Installs ros desktop
# - Install rosinstall and wstool
# - Does rosdep init
#
# Requires:
# - puppetlabs/apt
#
# Sample Usage:
#  ros::install { 'hydro': }
#
define ros::install(
  $ensure      = present,
  $ros_release = $title,
) {
  include apt
  $ros_package = "ros-${ros_release}-desktop-full"

  # Needed for key adding
  package { 'wget': ensure => installed }

  apt::key { 'ros':
    key        => 'B01FA116',
    key_source => 'http://packages.ros.org/ros.key',
    notify => Exec['apt_update'],
    #ensure => $ensure,
  }

  # Activates restricted, universe, multiverse
  $deb_line_match_1 = '^#\(deb http:.*'
  $deb_line_match_2 += '\(-updates\)\? \(restricted\|universe\|multiverse\)\)'
  $deb_line_match = "${deb_line_match_1}${lsbdistcodename}${deb_line_match_2}"
  exec { 'ros-activate-repos':
    command => "/bin/sed -i\".bak-$(date +\'%Y%m%d-%H%M%S\')\" 's/$deb_line_match/\\1/' /etc/apt/sources.list",
    onlyif  => "/bin/grep '$deb_line_match' /etc/apt/sources.list"
  }

  apt::source { "ros":
    location    => "http://packages.ros.org/ros/ubuntu",
    repos       => "main",
    key         => 'B01FA116',
    include_src => false,
    require     => [ Package['wget'], Exec['ros-activate-repos'] ]
  }

  package {
    $ros_package:        ensure => present, require => Apt::Source['ros'];
    'python-wstool':     ensure => present, require => Apt::Source['ros'];
    'python-rosinstall': ensure => present, require => Apt::Source['ros'];
  }

  exec {'rosdep-init':
      command => '/usr/bin/rosdep init',
      require => Package["$ros_package"],
      creates => '/etc/ros/rosdep/sources.list.d/20-default.list';
  }
}
