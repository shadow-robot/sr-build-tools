import org.yaml.snakeyaml.Yaml
import groovy.mock.interceptor.MockFor

class SettingsParser {
    String yaml
    Map config
    List<Settings> settingsList = []

    static Logger loggerMock

    static void initializeMocks() {
        def loggerMockContext = new MockFor(Logger)
        loggerMockContext.ignore(~".*") {}
        loggerMock = loggerMockContext.proxyInstance([null])
    }

    SettingsParser(String yaml, String branchName = null) {
        initializeMocks()
        parseYaml(yaml)
        settingsList.add(new Settings(config, loggerMock, branchName))
    }

    def parseYaml(newYaml = null) {
        if (newYaml) yaml = newYaml
        def parser = new Yaml()
        config = parser.load(yaml)
    }

}