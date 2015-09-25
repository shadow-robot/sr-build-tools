# Build Tools Modules

## List of modules

  * **build_pr_only** - skip build after commit if it is not PR 
  * **check_cache** - checks if ROS Indigo was already installed by build tools. If not, install it. 
  In case of [Docker Hub](https://hub.docker.com/r/shadowrobot/ubuntu-ros-indigo-build-tools/) detects installed ROS and do nothing.
  * **build** - build project using catkin_make.
  * **unit_tests** - run unit tests and place results in special folder if defined by CI server (e.g. artifacts for Circle CI)
  * **check_build** - long running module. Compile independently each package in the project cleaning devel and build folder beforehand and check if all dependencies are declared in CMakeList.txt correctly.
  * **code_style_check** - run [roslint](http://wiki.ros.org/roslint) to check C++ and Python code in all packages of the project.
  * **check_deb_make** - generate Debian package files using bloom and try to install them. Check if installation is working correctly. It assumes that packages installed from source code would be available to rosdep during package deployment.
  * **complete_deb_check** - the same as **check_deb_make** but it require all packages to be accessible to rosdep during module execution. 
  * **python_code_coverage** - generate code coverage for Python code
  * **cpp_code_coverage** - generate code coverage for C++ code
  * **code_coverage** - generate code coverage for Python and C++ code
  * **codecov_tool** - post Python and C++ code coverage results to [CodeCov](https://codecov.io)
