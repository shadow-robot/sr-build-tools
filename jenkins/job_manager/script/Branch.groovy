class Branch {
    String name, sha
    Boolean trunk, head
    Repository repository
    Settings settings
    Logger logger
    ArrayList<PullRequest> pullRequests = new ArrayList<PullRequest>()

    Branch(String name, String sha, Repository repository) {
        this.name = name
        this.sha = sha
        this.repository = repository
        this.logger = repository.logger
        logger.info("Creating ${name} branch of ${repository.url}...")
    }

    def getSettingsFromRepository() {
        def settingsList = repository.getSettingsFromFile('jenkins.yml', name)
        settings = settingsList.get(0)
        logger.debug(settings.toString())
    }

    String toString() {
        return "${name}(${head ? 'HEAD' : ''}${trunk ? 'Trunk' : ''})"
    }
}
