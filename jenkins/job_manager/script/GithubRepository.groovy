import groovy.transform.InheritConstructors
import groovy.json.JsonSlurper

@InheritConstructors
class GithubRepository extends Repository {
    static String githubBaseUrl = 'https://github.com'
    static String githubRawUrl = 'https://raw.githubusercontent.com'
    String organisationName, name
    def repositoryDetails = [:]

    GithubRepository(String organisationName, String name, credentials, Logger logger) {
        super("${githubBaseUrl}/${organisationName}/${name}", name, credentials, logger)
        this.name = name
        this.organisationName = organisationName
    }

    def getFileContents(String filePath, String branchName = null, String commitSha = null) {
        def fileUrl
        if (commitSha) {
            fileUrl = "${githubRawUrl}/${organisationName}/${name}/${commitSha}/${filePath}"
        } else if (branchName) {
            branchName = URLEncoder.encode(branchName, "UTF-8")
            fileUrl = "${githubRawUrl}/${organisationName}/${name}/${branchName}/${filePath}"
        } else {
            def headBranch = branches.find { branch -> branch.head }
            if (headBranch) {
                logger.info("Getting ${filePath} from main branch (${headBranch.name}) of ${url}.")
                fileUrl = "${githubRawUrl}/${organisationName}/${name}/${headBranch.name}/${filePath}"
            } else {
                logger.warn("No branch of ${url} is known to be the main branch, so assuming that ${filePath} will resolve.")
                fileUrl = "${githubRawUrl}/${organisationName}/${name}/${filePath}"
            }
        }
        def command = "curl -f --user ${credentials.username}:${credentials.password} ${fileUrl}"
        def sout = new StringBuilder(), serr = new StringBuilder()
        def curlProcess = command.execute()
        curlProcess.consumeProcessOutput(sout, serr)
        curlProcess.waitForOrKill(10000)
        def stdout = sout.toString()
        if (curlProcess.exitValue()) {
            def stderr = serr.toString()
            if (stderr.contains("404")) {
                logger.info("Curl of ${fileUrl} failed: 404 not found!")
                return 404
            } else if (stderr.contains("400")) {
                logger.warn("Curl of ${fileUrl} failed: 400 bad request!")
                return 400
            } else {
                logger.warn("Curl of ${fileUrl} failed: unknow error:")
                logger.warn("stdout: ${stdout}")
                logger.warn("stderr: ${stderr}")
                return -1
            }
        } else {
            logger.info("Curl of ${fileUrl} successful!")
            return stdout
        }
    }

    def apiQuery(String type = null, Map args = [:], token = null) {
        def url = "https://api.github.com/repos/${organisationName}/${name}"
        if (type) url += "/${type}"
        def redactedUrl = url
        String parameters = ""
        args.eachWithIndex { arg, index ->
            if (index > 0) parameters += "&"
            parameters += "${arg.key}=${URLEncoder.encode(arg.value, 'UTF-8')}"
        }
        if (token || args) {
            url += "?"
            redactedUrl += "?"
            if (token) {
                url += "access_token=${token}"
                if (args) {
                    url += "&${parameters}"
                    redactedUrl += parameters
                }
            } else {
                url += parameters
                redactedUrl += parameters
            }
        }
        def command = "curl -f ${url}"
        def sout = new StringBuilder(), serr = new StringBuilder()
        def curlProcess = command.execute()
        curlProcess.consumeProcessOutput(sout, serr)
        curlProcess.waitForOrKill(10000)
        def stdout = sout.toString()
        if (curlProcess.exitValue()) {
            def stderr = serr.toString()
            if (stderr.contains("404")) {
                logger.info("Github API request for ${redactedUrl} failed: 404 not found!")
                return 404
            } else if (stderr.contains("400")) {
                logger.warn("Github API request for ${redactedUrl} failed: 400 bad request!")
                return 400
            } else {
                logger.warn("Github API request for ${redactedUrl}  failed: unknow error:")
                logger.warn("stdout: ${stdout}")
                logger.warn("stderr: ${stderr}")
                return -1
            }
        } else {
            logger.info("Github API request for ${redactedUrl}  successful!")
            def jsonSlurper = new JsonSlurper()
            def result
            try {
                result = jsonSlurper.parseText(stdout)
                return result
            } catch (Exception e) {
                logger.warn("Failed to parse JSON response from GitHub API")
                //logger.warn("${stdout}")
                return -1
            }
        }
    }

    def fetchBranches(retries = 5) {
        for (attempt in 1..retries) {
            if (attempt > 1) logger.info("Trying to fetch branches ${retries + 1 - attempt} more time(s).")
            def apiResponse = apiQuery("branches", [per_page: '100'], credentials.token)
            if (!apiResponse || (apiResponse instanceof Integer)) {
                logger.warn("Failed to fetch any branches for ${url}")
            } else {
                branches = new ArrayList<Branch>()
                apiResponse.each { branch ->
                    def newBranch = new Branch(branch.name, branch.commit.sha, this)
                    if (branch.name == repositoryDetails.default_branch) {
                        headSha = branch.commit.sha
                        mainBranch = newBranch
                        newBranch.head = true
                    }
                    branches.push(newBranch)
                }
                logger.info("${branches.size()} branches of ${url} found")
                logger.debug("${branches*.name}")
                return true
            }
        }
        logger.error("Failed to get branches for ${url} after ${retries} attempts.")
        return false
    }

    def fetchPullRequests(retries = 5) {
        for (attempt in 1..retries) {
            if (attempt > 1) logger.info("Trying to fetch pull requests ${retries + 1 - attempt} more time(s).")
            def apiResponse = apiQuery("pulls", [per_page: '100', state: 'open'], credentials.token)
            if (apiResponse instanceof Integer) {
                logger.warn("Failed to fetch pull requests for ${url}")
            } else {
                pullRequests = new ArrayList<PullRequest>()
                if (apiResponse) {
                    apiResponse.findAll { it.state == 'open' }.each { pullRequest ->
                        def newPullRequest = new PullRequest(pullRequest.number.toInteger(), pullRequest.head.sha)
                        def branch = branches.find { it.name == pullRequest.head.ref }
                        if (branch) {
                            newPullRequest.branch = branch
                            branch.pullRequests.push(newPullRequest)
                            pullRequests.push(newPullRequest)
                        }
                    }
                }
                logger.info("${pullRequests.size()} open pull requests of ${url} found")
                logger.debug("${pullRequests}")
                return true
            }
        }
        logger.error("Failed to get branches for ${url} after ${retries} attempts.")
        return false
    }

    def fetchRepoDetails(retries = 5) {
        for (attempt in 1..retries) {
            if (attempt > 1) logger.info("Trying to fetch Github repo details ${retries + 1 - attempt} more time(s).")
            def apiResponse = apiQuery(null, [:], credentials.token)
            if (!apiResponse || (apiResponse instanceof Integer)) {
                logger.warn("Failed to fetch repo details for ${url}")
            } else {
                repositoryDetails = apiResponse
                logger.info("Repository details of ${url} found")
                logger.debug("${repositoryDetails}")
                return true
            }
        }
        logger.error("Failed to get repo details for ${url} after ${retries} attempts.")
        return false
    }

    def getReferences() {
        if (!fetchRepoDetails()) return false
        if (!fetchBranches()) return false
        if (!fetchPullRequests()) return false
        return true
    }
}


