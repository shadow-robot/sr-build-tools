class Branch {
    String name, sha
    Boolean trunk, head
    Repository repository
    List<Settings> settings
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
        settings = settingsList
        logger.debug(settings.toString())
    }

    String toString() {
        return "${name}(${head ? 'HEAD' : ''}${trunk ? 'Trunk' : ''})"
    }
}
