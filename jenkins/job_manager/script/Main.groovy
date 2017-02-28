
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
        "println 'Here 1 !!!\n" +
        "def logger = new Logger(getBinding().out, Logger.Verbosity.DEBUG)\n" +
//        "def jobManager = new JobManager(credentials, logger, githubRepoNames, Jenkins.instance)\n" +
//        "if (jobManager.processRepositories()) {\n" +
//        "    jobManager.processJobs()\n" +
        "    logger.info('Finished.')\n" +
//        "}\n" +
        "println 'Here 11 !!!\n" +
        "return true")
