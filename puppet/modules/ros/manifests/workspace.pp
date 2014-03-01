# Definition: ros::workspace
#
# This resource setups ros workspaces.
#
# Parameters:
# - The $dir path of the workspace, it's directory. Defaults to title.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#  ros::workspace { '/home/ros/hydro_ws': }
#
define ros::workspace (
  $dir         = $title,
  $ensure      = present,
  $ros_release = "hydro",
  $ros_user    = "",
) {

  file { $dir:
    ensure   => directory,
    owner    => $ros_user,
    group    => "ros",
    require  => Ros::User[$ros_user],
  }
  ->
  file { "$dir/src":
    ensure   => directory,
    owner    => $ros_user,
    group    => "ros",
  }

}
