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
  ->
  exec { "catkin_init_workspace-$dir":
    command => "bash -c 'source /opt/ros/$ros_release/setup.bash && catkin_init_workspace'",
    cwd     => "$dir/src",
    user    => $ros_user,
    creates => "$dir/src/CMakeLists.txt"
  }
  ->
  exec { "catkin_make-$dir-init":
    command => "bash -c 'source /opt/ros/$ros_release/setup.bash && catkin_make'",
    cwd     => "$dir",
    user    => $ros_user,
  }
}
