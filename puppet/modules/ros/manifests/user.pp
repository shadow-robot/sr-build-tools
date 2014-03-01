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
  # name           = the the users name
  $ensure          = present,
  $ros_release     = "hydro",
  $workspace_setup = "",
  $password        = "",
) {
  # XXX Should we depend on ros::install here?
  Ros::User["$name"] -> Ros::Install["$ros_release"]

  if $workspace_setup == "" {
    $_workspace_setup = "/opt/ros/$ros_release/setup.bash"
  }
  else {
    $_workspace_setup = $workspace_setup
  }

  group { 'ros':
    ensure => present
  }

  user { "$name":
    ensure     => present,
    shell      => '/bin/bash',
    home       => "/home/$name",
    gid        => "ros",
    password   => sha1($password),
    managehome => true,
    require    => [ Group["ros"] ],
  }

  exec {"rosdep-update-$name":
      # user option doesn't set env right, so use su - to run as the new user
      command   => "/bin/su $name - -c '/usr/bin/rosdep update'",
      logoutput => on_failure,
      require   => User[$name],
  }

  # Sort the bashrc
  exec { "clean-bashrc-$name":
    command => "sed -i\".bak-$(date +\'%F-%T\')\" /^source.*setup.bash.*$/d /home/$name/.bashrc",
    require => User[$name]
  }
  ->
  exec { "bashrc-$name":
    command => "echo 'source $_workspace_setup' >> /home/$name/.bashrc"
  }
}
