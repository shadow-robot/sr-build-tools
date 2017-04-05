class Repository implements GroovyInterceptable {
    String url, authenticatedUrl, headSha, name
    Settings settings
    Logger logger
    ArrayList<Branch> branches
    ArrayList<PullRequest> pullRequests
    def jobs = []
    def credentials
    Branch mainBranch

    Repository(String url, String name, credentials, Logger logger) {
        this.url = url
        this.credentials = credentials
        this.authenticatedUrl = url.replace('https://', "https://${credentials.username}:${credentials.password}@")
        this.logger = logger
        this.name = name
    }

    def process(Settings defaultSettings) {
        if (!getReferences()) return false
        def settingsList = getSettingsFromFile()
        settings = settingsList.get(0)
        settings.source = Settings.Source.TRUNK
        markTrunks()
        branches.findAll { it.head || it.trunk || it.pullRequests }.each { it.getSettingsFromRepository() }
        generateJobs(defaultSettings)
        logger.debug("Processed ${this}")
        return true
    }

    String toString() {
        return """Repository: ${url}
      Branches: ${branches}
      Pull Requests: ${pullRequests}
      Jobs: ${jobs}"""
    }

    def getFileContents(String filePath, String branchName = null, String commitSha = null) {
        logger.error('Getting file contents from a generic remote git repository is not yet supported! Perhaps you meant to use the Github repository sub-class?')
        return null
    }

    List<Settings> getSettingsFromFile(String filePath = 'jenkins.yml', String branchName = null, Integer retries = 5) {
        for (attempt in 1..retries) {
            def settingsYaml = getFileContents(filePath, branchName)
            if (settingsYaml instanceof Integer) {
                switch (settingsYaml) {
                    case 404:
                        logger.warn("${url} does not have a ${filePath} in the ${branchName ?: 'main'} branch.")
                        return [new Settings(true, logger)]
                    case 400:
                        logger.warn("Attempted curl of ${filePath} from ${url} resulted in a 400: Bad Request error.")
                        break
                    case -1:
                        logger.warn("Attempted curl of ${filePath} from ${url} resulted in an unknown error.")
                        break
                }
            } else {
                try {
                    def settingsParserInstance = new SettingsParser(settingsYaml, logger, branchName)
                    def settingsInstance = settingsParserInstance.settingsList
                    return settingsInstance
                } catch (Exception e) {
                    logger.warn("Failed to parse ${filePath}. Contents:")
                    logger.warn(settingsYaml)
                    logger.warn(e.toString())
                }
            }
            logger.info("Retrying ${retries - attempt} more times.")
        }
        logger.error("Ultimately failed to get settings from jenkins.yml from ${url} after ${retries} attempts.")
        return [new Settings(false, logger)]
    }

    def getReferences() {
        def command = "git ls-remote ${authenticatedUrl}"
        def sout = new StringBuilder(), serr = new StringBuilder()
        def gitLsProcess = command.execute()
        gitLsProcess.consumeProcessOutput(sout, serr)
        gitLsProcess.waitForOrKill(10000)
        def output = sout.toString()
        def error = serr.toString()
        if (gitLsProcess.exitValue()) {
            logger.error("Git ls remote of ${url} failed!")
            logger.error(output)
            logger.error(error)
            return false
        }
        def headMatcher = output =~ /(?m)^([0-9a-f]*)\s*HEAD$/
        if (headMatcher.getCount()) {
            headSha = headMatcher[0][1]
        } else {
            logger.warn("No HEAD found for ${url}")
        }
        def branchMatcher = output =~ /(?m)^([0-9a-f]*)\s*refs\/heads\/(.*)$/
        if (branchMatcher.getCount()) {
            branches = new ArrayList<Branch>()
            branchMatcher.each { match ->
                branches.push(new Branch(match[2], match[1], this))
            }
            logger.info("${branches.size()} branches of ${url} found")
            logger.debug("${branches*.name}")
        } else {
            logger.warn("Warning: no branches found for ${url}")
            return false
        }
        branches.findAll { branch -> branch.sha == headSha }.each { match -> match.head = true }
        mainBranch = branches.find { it.head }
        def prMatcher = output =~ /(?m)^([0-9a-f]*)\s*refs\/pull\/([0-9]*)\/.*$/
        pullRequests = new ArrayList<PullRequest>()
        if (prMatcher.getCount()) {
            prMatcher.each { match ->
                def pullRequest = new PullRequest(match[2].toInteger(), match[1])
                def branch = branches.find { it.sha == pullRequest.sha }
                if (branch) {
                    pullRequest.branch = branch
                    branch.pullRequests.push(pullRequest)
                    pullRequests.push(pullRequest)
                }
            }
            logger.info("${pullRequests.size()} pull requests found for ${url}")
            logger.debug("${pullRequests}")
        } else {
            logger.warn("No pull requests found for ${url}")
        }
        return true
    }

    def markTrunks() {
        if (settings && settings.settings && settings.settings.trunks) {
            branches.findAll {
                settings.settings.trunks.name.collect().contains(it.name)
            }.each { trunk -> trunk.trunk = true }
        }
    }

    def generateJobs(Settings defaultSettings) {
        branches.findAll { it.trunk || it.head }.each { branch ->

            if (branch.settings.size() > 1){
                for (int i = 0; i < branch.settings.size(); i++){
                    jobs.push(new Job(branch, defaultSettings, i))
                }
            }else {
                jobs.push(new Job(branch, defaultSettings))
            }
        }

        pullRequests.findAll { it.branch }.each { pullRequest ->

            if (pullRequest.branch.settings.size() > 1){
                for (int i = 0; i < pullRequest.branch.settings.size(); i++){
                    jobs.push(new Job(pullRequest, defaultSettings, i))
                }
            } else {
                jobs.push(new Job(pullRequest, defaultSettings))
            }
        }
    }
}
