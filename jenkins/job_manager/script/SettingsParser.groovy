import org.yaml.snakeyaml.Yaml

class SettingsParser {
    String yaml
    Map config
    List<Settings> settingsList = []
    Logger logger
    boolean createdMultipleSettings

    SettingsParser(String yaml, Logger logger, String branchName = null) {
        this.logger = logger
        parseYaml(yaml)
        generateSettingsList(branchName)
    }

    def parseYaml(newYaml = null) {
        if (newYaml) {
            yaml = newYaml
        }
        def parser = new Yaml()
        config = parser.load(yaml)
    }

    def generateSettingsList(String branchName = null) {
        createdMultipleSettings = false

        if (branchName) {
            if (config.trunks && branchName in config.trunks.name) {
                def trunk = config.trunks.find { it.name == branchName }

                if (trunk.settings && trunk.settings.getClass() == ArrayList) {
                    fillSettingsList(trunk, branchName)
                }
            } else {
                if (config.branch && config.branch.parent) {
                    def trunk = config.trunks.find { it.name == config.branch.parent }

                    if (trunk.settings && trunk.settings.getClass() == ArrayList) {
                        fillSettingsList(trunk, branchName)
                    }
                    if (config.branch.settings && config.branch.settings.getClass() == ArrayList) {
                        fillSettingsList(config.branch, branchName)
                    }
                }
            }
        }

        if (!createdMultipleSettings){
            settingsList.add(new Settings(config, logger, branchName))
        }
    }

    def fillSettingsList(Map trunk, String branchName = null){
        createdMultipleSettings = true
        def trunkSettingsList = trunk.settings.clone()
        trunk.settings.clear()
        for (int j = 0; j < trunkSettingsList.size(); j++) {
            trunk.settings = trunkSettingsList[j]
            settingsList.add(new Settings(config, logger, branchName))
        }
    }
}