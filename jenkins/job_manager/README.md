In order to run main job manager please put the following code to Jenkins job

```Groovy

credentials = [username: "jenkins_username",
               password: "jenkins_password",
               token: "jenkins_token"]

githubRepoNames = ['sr_interface', 'build-servers-check'] // Put here needed repositories
toolsetBranch = "master"
def mainScriptUrl = "https://raw.githubusercontent.com/shadow-robot/sr-build-tools/${toolsetBranch}/jenkins/" +
        "job_manager/script/Main.groovy"

evaluate(mainScriptUrl.toURL().getText())



```

In order to run test please use the following code in your Jenkins job

```Groovy

toolsetBranch = "master"
def testSuiteScriptUrl = "https://raw.githubusercontent.com/shadow-robot/sr-build-tools/${toolsetBranch}/jenkins/" +
        "job_manager/test/TestSuite.groovy"

evaluate(testSuiteScriptUrl.toURL().getText())
```
