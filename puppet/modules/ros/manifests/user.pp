# Definition: ros::user
#
# This resource setups ros users.
#
# Parameters:
# - The $name of the user
#
# Actions:
# - Adds the $name user. Default is title.
# - Ensures group 'ros' is present.
# - Runs rosdep update for the user.
#
# Requires:
#
# Sample Usage:
#  ros::user { 'ros': }
#
# See Also:
# - http://wiki.ros.org/hydro/Installation/Ubuntu
#
define ros::user (
  #$name   = $title,
  $ensure = present,
) {
  # XXX Should we depend on ros::install here?
  notify { "User: $name": }

  group { 'ros':
    ensure => present
  }

  user { "$name":
    ensure     => present,
    shell      => '/bin/bash',
    gid        => "ros",
    password   => "ros",
    managehome => true,
    require    => [ Group["ros"] ],
  }

  exec {"rosdep-update-$name":
      # user option doesn't set env right, so use su - to run as the new user
      command   => "/bin/su $name - -c '/usr/bin/rosdep update'",
      logoutput => on_failure,
      require   => Exec['rosdep-init'],
  }
}
