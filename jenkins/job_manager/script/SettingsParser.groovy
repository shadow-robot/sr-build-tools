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
        if (newYaml) yaml = newYaml
        def parser = new Yaml()
        config = parser.load(yaml)
    }


    def generateSettingsList(String branchName = null) {

        createdMultipleSettings = false

        if (branchName) {
            if (config.trunks && branchName in config.trunks.name) {
                // This is a main branch
                def trunk = config.trunks.find { it.name == branchName }
                // If there are settings defined in this main branch
                if (trunk.settings) {
                    //if there are multiple settings
                    if (trunk.settings.getClass() == ArrayList){

                        createdMultipleSettings = true

                        def trunkSettingsList = trunk.settings.clone()
                        trunk.settings.clear()
                        for (int j=0; j < trunkSettingsList.size(); j++){
                            trunk.settings = trunkSettingsList[j]
                            settingsList.add(new Settings(config, logger, branchName))
                        }
                    }
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
                            //if there are multiple settings
                            if (trunk.settings.getClass() == ArrayList){

                                createdMultipleSettings = true

                                def trunkSettingsList = trunk.settings.clone()
                                trunk.settings.clear()
                                for (int j=0; j < trunkSettingsList.size(); j++){
                                    trunk.settings = trunkSettingsList[j]
                                    settingsList.add(new Settings(config, logger, branchName))
                                }
                            }
                        }

                        //if different toolsets specified for a parent
                        if(config.branch.settings){
                            if (config.branch.settings.getClass() == ArrayList){

                                createdMultipleSettings = true

                                def toolsetSettingsList = config.branch.settings.clone()
                                config.branch.settings.clear()
                                for (int j=0; j < toolsetSettingsList.size(); j++){
                                    config.branch.settings = toolsetSettingsList[j]
                                    settingsList.add(new Settings(config, logger, branchName))
                                }

                            }

                        }
                    }
                }
            }

        }

        if (!createdMultipleSettings){
            settingsList.add(new Settings(config, logger, branchName))
        }

    }
}