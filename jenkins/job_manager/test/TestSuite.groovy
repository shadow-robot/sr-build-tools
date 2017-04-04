if (!binding.variables.containsKey("toolsetBranch")) {
    toolsetBranch = "master"
}

def baseUrl = "https://raw.githubusercontent.com/shadow-robot/sr-build-tools/${toolsetBranch}/jenkins/job_manager"
def baseScriptUrl = "${baseUrl}/script"
def baseTestUrl = "${baseUrl}/test"
def timestamp = System.currentTimeMillis()

def result = evaluate(
        "${baseScriptUrl}/Logger.groovy?u=${timestamp}".toURL().getText() + "\n" +
        "${baseScriptUrl}/SettingsParser.groovy?u=${timestamp}".toURL().getText() + "\n" +
        "${baseScriptUrl}/Settings.groovy?u=${timestamp}".toURL().getText() + "\n" +
        "${baseScriptUrl}/Branch.groovy?u=${timestamp}".toURL().getText() + "\n" +
        "${baseScriptUrl}/Job.groovy?u=${timestamp}".toURL().getText() + "\n" +
        "${baseScriptUrl}/PullRequest.groovy?u=${timestamp}".toURL().getText() + "\n" +
        "${baseScriptUrl}/Repository.groovy?u=${timestamp}".toURL().getText() + "\n" +
        "${baseScriptUrl}/GithubRepository.groovy?u=${timestamp}".toURL().getText() + "\n" +
        "${baseTestUrl}/SettingsTest.groovy?u=${timestamp}".toURL().getText() + "\n" +
        "${baseTestUrl}/JobTest.groovy?u=${timestamp}".toURL().getText() + "\n" +
        "${baseTestUrl}/RepositoryTest.groovy?u=${timestamp}".toURL().getText() + "\n" +
        "return org.junit.runner.JUnitCore.runClasses(SettingsTest.class, JobTest.class, RepositoryTest.class)")

println "Executed " + result.getRunCount() + " test(s) for " + (result.getRunTime() / 1000) + " second(s)"
println "Ignored test(s) count " + result.getIgnoreCount()
println "Failed test(s) count "  + result.getFailureCount() + "\n"

if (result.wasSuccessful()) {
    println "Tests passed\n"
    return true
}

println "Tests Failed\n"
result.getFailures().each {
    println it.toString() + "\n"
}

return false