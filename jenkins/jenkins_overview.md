# Jenkins
There is a regularly-scheduled job on Jenkins, that attempts to create automated Jenkins jobs for any trunks or pending pull requests in each repository.

The job runs a script that parses a checked-in file, `jenkins.yml`, in the root of each branch of each repo. [The default `jenkins.yml`](https://github.com/shadow-robot/sr-build-tools/blob/master/config/default_jenkins.yml), which is used if a branch and repo do not contain a `jenkins.yml`, serves as a good template.

## Job Creation Process
### 1. Trunk Identification
In order to establish which branches are considered to be trunks, the script first parses the `jenkins.yml` in the `HEAD` commit of a repository. This is the latest commit on the main branch. 
Trunks are defined in this section:
```yaml
trunks:
  - name: indigo-devel
  - name: kinetic-devel
...
```
If there is no `jenkins.yml` in the main branch, [the default](https://github.com/shadow-robot/sr-build-tools/blob/master/config/default_jenkins.yml) is used; any branches with names matching the `trunks` defined therein will be considered trunks.
### 2. Pending Pull Request Identification
The script then uses a `git ls-remote <repo_url>` to obtain a list of branches and pull requests. Any pull requests attempting to merge a still-existent branch are included.
### 3. Job Configuration
Now that the script has a list of trunk branches and pending pull requests, it must configure a job for each.

Settings for each branch are parsed from the `jenkins.yml` file checked into said branch.

If a branch does not have a `jenkins.yml` file, the `jenkins.yml` in the trunk/main branch is used. If the trunk/main branch does not have a `jenkins.yml`, [the default](https://github.com/shadow-robot/sr-build-tools/blob/master/config/default_jenkins.yml) is used.

The `settings:` section contains the default settings for the new job.
```yaml
ubuntu:
  version: trusty
```
Specifies that the build should be run in Ubuntu Trusty.

```yaml
ros:
  release: indigo
```
Specifies that the build should be run against the Indigo release of ROS.

```yaml
docker:
  image: shadowrobot/build-tools
  tag: trusty-indigo
```
Specifies that the build should be run in a Docker container based on the `shadowrobot/build-tools:trusty-indigo` image.

```yaml
toolset:
  template_job_name: template_unit_tests_and_code_coverage
  modules:
    - check_cache
    - code_coverage
```
Specifies that the Jenkins job should be based on the `template_unit_tests_and_code_coverage` job, and the tasks ("modules") to be run by the job.

A branch's `jenkins.yml` may contain only the above fields, e.g.:
```yaml
settings:
  ubuntu:
    version: trusty
  docker:
    image: shadowrobot/ramcip
    tag: main
  ros:
    release: indigo
  toolset:
    template_job_name: template_unit_tests_and_code_coverage
    modules:
      - check_cache
      - code_coverage
```
However, the additional sections, `trunks` and `branch`, play an important role during the git workflow, and the `jenkins.yml` in a trunk should contain them, such that new branches inherit trunk job settings, while maintaining the ability to override them.

For example, the `kinetic-devel` trunk main contain the following `jenkins.yml`:
```yml
settings:
  ubuntu:
    version: trusty
  ros:
    release: indigo
  docker:
    image: shadowrobot/build-tools
    tag: trusty-indigo
  toolset:
    template_job_name: template_unit_tests_and_code_coverage
    modules:
      - check_cache
      - code_coverage

trunks:
  - name: indigo-devel
  - name: kinetic-devel
    settings:
      ubuntu:
        version: xenial
      ros:
        release: kinetic
      docker:
        tag: xenial-kinetic

branch:
  parent: kinetic-devel
```
When parsed in order to build the `kinetic-devel` jenkins job, settings in the `kinetic-devel` subsection of `trunks` will override the defaults provided in `settings`.

When a new branch is created from `kinetic-devel`, it will of course have the same `jenkins.yml`. The key difference is that when `jenkins.yml` is parsed in order to create a job for this branch, the `branch` section *is* parsed.

The optional `parent` value specifies a trunk from which this branch should inherit job settings from.

Importantly, the `settings` section may be duplicated in the `branch` section, and any values specified there will override both the trunk and default settings.

The end result is that new branches do not require any modification to their `jenkins.yml` in order for an automated jenkins job to be generated (when a pull request is created). If required, however, a branch can either inherit jenkins settings from an entirely different trunk, and/or override specific values.

### Example
The following `jenkins.yml` is in `indigo-devel`, which also happens to be the main branch. 
```yaml
settings:
  ubuntu:
    version: trusty
  ros:
    release: indigo
  docker:
    image: shadowrobot/build-tools
    tag: trusty-indigo
  toolset:
    template_job_name: template_unit_tests_and_code_coverage
    modules:
      - check_cache
      - code_coverage

trunks:
  - name: indigo-devel
  - name: kinetic-devel
    settings:
      ubuntu:
        version: xenial
      ros:
        release: kinetic
      docker:
        tag: xenial-kinetic
      toolset:
        modules:
          - kinetic-devel-specific-module
branch:
  parent: indigo-devel
```
The `kinetic-devel` `jenkins.yml` has only one difference:
```yaml
branch:
  parent: kinetic-devel
```
The trunks' `jenkins.yml` differ in this way such that any branches taken from them correctly inherit respective their trunks' settings.

When the Jenkins job creation script creates jobs for this repo, it parses the trunk names from the above, obtaining `indigo-devel` and `kinetic-devel`.

When creating the `indigo-devel` job, settings in the top-level `settings` are used, as the `indigo-devel` `settings` is empty, and `branch` is ignored when parsing trunks. This results in:
```yaml
settings:
  ubuntu:
    version: trusty
  ros:
    release: indigo
  docker:
    image: shadowrobot/build-tools
    tag: trusty-indigo
  toolset:
    template_job_name: template_unit_tests_and_code_coverage
    modules:
      - check_cache
      - code_coverage
```
When creating the `kinetic-devel` job, settings in the top-level `settings` are combined with those in `trunks: kinetic-devel: settings`. Again, `branch` is ignored, as `kinetic-devel` is a trunk. This results in:
```yaml
settings:
  ubuntu:
    version: xenial
  ros:
    release: kinetic
  docker:
    image: shadowrobot/build-tools
    tag: xenial-kinetic
  toolset:
    template_job_name: template_unit_tests_and_code_coverage
    modules:
      - kinetic-devel-specific-module
```
Note that the module lists are not combined: the `modules` list from `kinetic-devel` overrides the default `modules` list completely.

Now, a new branch is created from `kinetic-devel`: `kinetic-devel-branch`. Because we want to run some different modules when testing this branch, we modify `jenkins.yml` as follows:
```yaml
...
branch:
  parent: kinetic-devel
  settings:
    toolset:
      modules:
        - branch-specific-module
```
When the above is parsed in the context of creating a job for `kinetic-devel-branch`, settings in the top-level `settings` are combined with those in `trunks: kinetic-devel: settings`, due to `parent: kinetic-devel`). This time, `branch` is *not* ignored, as `kinetic-devel-branch` is a branch. Settings from `branch: settings` now override all other settings, resulting in:
```yaml
settings:
  ubuntu:
    version: xenial
  ros:
    release: kinetic
  docker:
    image: shadowrobot/build-tools
    tag: xenial-kinetic
  toolset:
    template_job_name: template_unit_tests_and_code_coverage
    modules:
      - branch-specific-module
```
Note that again, the module lists are not combined.
### 4. Multiple Job Parsing
It is also possible to create multiple jobs for a single branch. In the `jenkins.yml` file, if the settings section consists of more then one field, i.e. it is an array, multiple jobs will be created, amount of jobs corresponding to the size of settings array. For example, lets consider following format of trunks and branch sections in the `jenkins.yml` file:

```yaml
...
trunks:
  - name: indigo-devel
  - name: kinetic-devel
    settings:
      - ubuntu:
          version: xenial
        ros:
          release: kinetic
        docker:
          tag: xenial-kinetic
      - ubuntu:
          version: willy
        ros:
          release: kinetic
        docker:
          tag: willy-kinetic
branch:
  parent: kinetic-devel
```
In this case, two jobs will be created. First one will have ubuntu version set to `xenial`, ros release to `kinetic`, and will be using `xenial-kinetic` docker image. The second one will have ubuntu version set to `willy`, ros release to `kinetic` and the build will be run on `willy-kinetic` docker image.

The naming convension for created jobs is as follows: `auto_[repository name]_[branch name]_[index]_[ros release]`, indexing starting from 0. Using the example above, for a repository name `example_repo` and branch name `example_branch`, following two jobs would be created: `auto_example_repo_example_branch_0_kinetic` and `auto_example_repo_example_branch_1_kinetic`. 

In case of `jenkins.yml` file changing from single settings set to multiple settings sets, the existing job will be deleted and new multiple jobs will be created in its place, with proper naming and corresponding settings. The functionality works also the other way around, deleting multiple jobs and creating a single job with a default naming in case of `jenkins.yml` file changing from having multiple sets of settings to a single set of settings. It would also work in case of changing the number of settings sets within the `jenkins.yml` file.

### Multiple Jobs Example
Following `jenkins.yml` file is in a branch `multiple_jobs_test` of `sr_core` repository:
```yaml
settings:
  ubuntu:
    version: trusty
  docker:
    image: shadowrobot/build-tools
    tag: trusty-indigo
  ros:
    release: indigo
  toolset:
    template_job_name: template_unit_tests_and_code_coverage
    modules:
      - check_cache
      - code_coverage
trunks:
  - name: new-version-devel
  - name: kinetic-devel
    settings:
      ubuntu:
        version: xenial
      ros:
        release: kinetic
      docker:
        tag: xenial-kinetic

branch:
  parent: new-version-devel
  settings:
    - toolset:
        modules:
          - check_cache
          - software_tests
    - toolset:
        template_job_name: my_second_template
        modules:
          - code_style_check
```
Since the branch inherits settings from new-version-devel trunk parent, for which settings field is an array, two jobs are created: `auto_sr_core_jenkins_multiple_jobs_test_0_indigo` and `auto_sr_core_jenkins_multiple_jobs_test_0_indigo`. The 0 index job has settings corresponding to following:
```yaml
settings:
  ubuntu:
    version: trusty
  docker:
    image: shadowrobot/build-tools
    tag: trusty-indigo
  ros:
    release: indigo
  toolset:
    template_job_name: template_unit_tests_and_code_coverage
    modules:
      - check_cache
      - software_tests
``` 
and the 1 index job:
```yaml
settings:
  ubuntu:
    version: trusty
  docker:
    image: shadowrobot/build-tools
    tag: trusty-indigo
  ros:
    release: indigo
  toolset:
    template_job_name: my_second_template
    modules:
      - code_style_check
``` 
Now lets modify the `jenkins.yml` file to following format:
```yml
settings:
  ubuntu:
    version: trusty
  docker:
    image: shadowrobot/build-tools
    tag: trusty-indigo
  ros:
    release: indigo
  toolset:
    template_job_name: template_unit_tests_and_code_coverage
    modules:
      - check_cache
      - code_coverage
trunks:
  - name: indigo-devel
  - name: kinetic-devel
    settings:
      - ubuntu:
          version: xenial
        ros:
          release: kinetic
        docker:
          tag: xenial-kinetic
      - ubuntu:
          version: willy
        ros:
          release: kinetic
        docker:
          tag: willy-kinetic
      - ubuntu:
          version: trusty
        ros:
          release: kinetic
        docker:
          tag: trusty-kinetic
branch:
  parent: kinetic-devel
```
Now the two existing jobs are deleted and in their place three now jobs are created: `auto_sr_core_jenkins_multiple_jobs_test_0_kinetic`, `auto_sr_core_jenkins_multiple_jobs_test_1_kinetic`, `auto_sr_core_jenkins_multiple_jobs_test_2_kinetic`, each corresponding to following settings set respectively:  
Index 0:
```yaml
settings:
  ubuntu:
    version: xenial
  docker:
    image: shadowrobot/build-tools
    tag: xenial-kinetic
  ros:
    release: kinetic
  toolset:
    template_job_name: template_unit_tests_and_code_coverage
    modules:
      - check_cache
      - code_coverage
``` 
Index 1:
```yaml
settings:
  ubuntu:
    version: willy
  docker:
    image: shadowrobot/build-tools
    tag: willy-kinetic
  ros:
    release: kinetic
  toolset:
    template_job_name: template_unit_tests_and_code_coverage
    modules:
      - check_cache
      - code_coverage
``` 
Index 2:
```yaml
settings:
  ubuntu:
    version: trusty
  docker:
    image: shadowrobot/build-tools
    tag: trusty-kinetic
  ros:
    release: kinetic
  toolset:
    template_job_name: template_unit_tests_and_code_coverage
    modules:
      - check_cache
      - code_coverage
``` 
Finally, lets change the `jenkins.yml` file once again:
```yml
settings:
  ubuntu:
    version: trusty
  docker:
    image: shadowrobot/build-tools
    tag: trusty-indigo
  ros:
    release: indigo
  toolset:
    template_job_name: template_unit_tests_and_code_coverage
    modules:
      - check_cache
      - code_coverage
trunks:
  - name: indigo-devel
  - name: kinetic-devel
    settings:
      - ubuntu:
          version: willy
        ros:
          release: kinetic
        docker:
          tag: willy-kinetic
      - ubuntu:
          version: trusty
        ros:
          release: kinetic
        docker:
          tag: trusty-kinetic
branch:
  parent: kinetic-devel
```
Now one of the existing jobs is deleted, two are remaining: `auto_sr_core_jenkins_multiple_jobs_test_0_kinetic`, `auto_sr_core_jenkins_multiple_jobs_test_1_kinetic`. However, note that in this case, the settings corresponding to the job names have changed. Job with index 0 has following settings:
```yaml
settings:
  ubuntu:
    version: willy
  docker:
    image: shadowrobot/build-tools
    tag: willy-kinetic
  ros:
    release: kinetic
  toolset:
    template_job_name: template_unit_tests_and_code_coverage
    modules:
      - check_cache
      - code_coverage
``` 
and the job with index 1 has settings:
```yaml
settings:
  ubuntu:
    version: trusty
  docker:
    image: shadowrobot/build-tools
    tag: trusty-kinetic
  ros:
    release: kinetic
  toolset:
    template_job_name: template_unit_tests_and_code_coverage
    modules:
      - check_cache
      - code_coverage
``` 
