// Jenkins job can have the following code
//
//credentials = [username: "jenkins_username",
//               password: "jenkins_password",
//               token: "jenkins_token"]
//
//githubRepoNames = ['sr_interface', 'build-servers-check']
//toolsetBranch = "master"
//def mainScriptUrl = "https://raw.githubusercontent.com/shadow-robot/sr-build-tools/${toolsetBranch}/jenkins/" +
//        "job_manager/script/Main.groovy"
//
//evaluate(mainScriptUrl.toURL().getText())
//
/////////////////////////////////////////////

if (!binding.variables.containsKey("credentials")) {
    println "Missing 'credentials' binding variable "
    return false
}

if (!binding.variables.containsKey("githubRepoNames")) {
    println "Missing 'githubRepoNames' binding variable"
    return false
}

if (!binding.variables.containsKey("toolsetBranch")) {
    toolsetBranch = "master"
}

def baseImageUrl = "https://raw.githubusercontent.com/shadow-robot/sr-build-tools/${toolsetBranch}/jenkins/" +
        "job_manager/script/"

evaluate("${baseImageUrl}/Logger.groovy".toURL().getText() + "\n" +
        "${baseImageUrl}/Settings.groovy".toURL().getText() + "\n" +
        "${baseImageUrl}/Branch.groovy".toURL().getText() + "\n" +
        "${baseImageUrl}/Job.groovy".toURL().getText() + "\n" +
        "${baseImageUrl}/PullRequest.groovy".toURL().getText() + "\n" +
        "${baseImageUrl}/Repository.groovy".toURL().getText() + "\n" +
        "${baseImageUrl}/GithubRepository.groovy".toURL().getText() + "\n" +
        "${baseImageUrl}/JobManager.groovy".toURL().getText() + "\n" +
        "def logger = new Logger(getBinding().out, Logger.Verbosity.DEBUG)\n" +
        "def jobManager = new JobManager(credentials, logger, githubRepoNames, Jenkins.instance)\n" +
        "if (jobManager.processRepositories()) {\n" +
        "    jobManager.processJobs()\n" +
        "    logger.info('Finished.')\n" +
        "}\n" +
        "return true")
