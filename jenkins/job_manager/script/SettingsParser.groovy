import org.yaml.snakeyaml.Yaml
import groovy.mock.interceptor.MockFor

class SettingsParser {
    String yaml
    Map config
    List<Settings> settingsList = []

    static Logger loggerMock

    SettingsParser(String yaml, String branchName = null) {
        initializeMocks()
        parseYaml(yaml)
        def trunk = config.trunks.find {it.name == "kinetic-devel"}

        if (config.trunks && 'kinetic-devel' in config.trunks.name && trunk.settings.getClass() == ArrayList){

                def numOfKineticSettings = trunk.settings.size()
                def kineticSettings = trunk.settings.clone()
                trunk.settings.clear()

                for (def i=0; i < numOfKineticSettings; i++) {
                    trunk.settings = kineticSettings[i]
                    settingsList.add(new Settings(config, loggerMock, branchName))
                }

        } else {
              settingsList.add(new Settings(config, loggerMock, branchName))
        }
    }

    def parseYaml(newYaml = null) {
        if (newYaml) yaml = newYaml
        def parser = new Yaml()
        config = parser.load(yaml)
    }

    static void initializeMocks() {
        def loggerMockContext = new MockFor(Logger)
        loggerMockContext.ignore(~".*") {}
        loggerMock = loggerMockContext.proxyInstance([null])
    }
}