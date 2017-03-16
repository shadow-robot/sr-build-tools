class Settings {
    Map config, settings
    enum Status {
        ERROR, NONE, GOOD
    }

    enum Source {
        DEFAULT, TRUNK, BRANCH
    }
    Status status = Status.ERROR
    Source source = Source.BRANCH
    Logger logger

    Settings(Boolean noJenkinsYml, Logger logger) {
        this.logger = logger
        if (noJenkinsYml) status = Status.NONE
    }

    Settings(Map config, Logger logger, String branchName = null) {
        this.config = config
        this.logger = logger
        processConfig(branchName)
        status = Status.GOOD
    }

    def processConfig(String branchName = null) {
        settings = config.settings
        if (branchName) {
            if (config.trunks && branchName in config.trunks.name) {
                // This is a main branch
                def trunk = config.trunks.find { it.name == branchName }
                // If there are settings defined in this main branch
                if (trunk.settings) {
                    // Use them to override repo settings
                    settings = merge(settings, trunk.settings)
                }
            } else {
                // This is not a main branch
                // If a template main branch is specified
                if (config.branch) {
                    if (config.branch.parent) {
                        // Find the main branch
                        def trunk = config.trunks.find { it.name == config.branch.parent }
                        // If the main branch has settings
                        if (trunk.settings) {
                            // Use them to override repo settings
                            settings = merge(settings, trunk.settings)
                        }
                    }
                    // If there are branch specific settings
                    if (config.branch.settings) {
                        // Use them to override branch and template settings
                        settings = merge(settings, config.branch.settings)
                    }
                }
            }
        } else {
            if (config.trunks) {
                settings.trunks = config.trunks
            }
        }
    }

    static Map merge(Map... maps) {
        Map result
        if (maps.size() == 0) {
            result = [:]
        } else if (maps.size() == 1) {
            result = maps[0]
        } else {
            result = [:]
            maps.each { map ->
                map.each { k, v ->
                    result[k] = result[k] instanceof Map ? merge(result[k], v) : v
                }
            }
        }
        result
    }

    String toString() {
        if (status != Status.GOOD) {
            return "[settings:${status}]"
        } else {
            return "[settings:source:${source}${settings}]"
        }
    }
}
