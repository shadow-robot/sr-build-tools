import org.yaml.snakeyaml.Yaml

class SettingsParser {
    String yaml
    Map config

    SettingsParser(String yaml) {
        parseYaml(yaml)
    }

    def parseYaml(newYaml = null) {
        if (newYaml) yaml = newYaml
        def parser = new Yaml()
        config = parser.load(yaml)
    }

}