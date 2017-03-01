// Jenkins job can have the following code
//
//toolsetBranch = "master"
//def testSuiteScriptUrl = "https://raw.githubusercontent.com/shadow-robot/sr-build-tools/${toolsetBranch}/jenkins/" +
//        "job_manager/test/TestSuite.groovy"
//
//evaluate(testSuiteScriptUrl.toURL().getText())
//
/////////////////////////////////////////////

if (!binding.variables.containsKey("toolsetBranch")) {
    toolsetBranch = "master"
}

def baseUrl = "https://raw.githubusercontent.com/shadow-robot/sr-build-tools/${toolsetBranch}/jenkins/job_manager"
def baseScriptUrl = "${baseUrl}/script"
def baseTestUrl = "${baseUrl}/test"

def result = evaluate(
        "${baseScriptUrl}/Logger.groovy".toURL().getText() + "\n" +
        "${baseScriptUrl}/Settings.groovy".toURL().getText() + "\n" +
        "${baseTestUrl}/SettingsTest.groovy".toURL().getText() + "\n" +
        "return org.junit.runner.JUnitCore.runClasses(SettingsTest.class)")

println "Executed " + result.getRunCount() + " tests for " + (result.getRunTime() / 1000) + " seconds"
println "Ignored tests " + result.getIgnoreCount()
println "Failed tests "  + result.getFailureCount()

if (result.wasSuccessful()) {
    println "Tests passed"
    return true
}

println "Tests Failed"
result.getFailures().each {
    println it.toString()
}

return false