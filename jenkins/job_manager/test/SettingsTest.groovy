import org.junit.Test
import groovy.mock.interceptor.MockFor

class SettingsTest {

    void checkBasicSettings(Settings config) {
        assert "trusty" == config.settings.ubuntu.version
        assert "shadowrobot/build-tools" == config.settings.docker.image
        assert "trusty-indigo" == config.settings.docker.tag
        assert "indigo" == config.settings.ros.release
        assert "my_template" == config.settings.toolset.template_job_name
        assert 2 == config.settings.toolset.modules.size()
        assert "check_cache" in config.settings.toolset.modules
        assert "code_coverage" in config.settings.toolset.modules
    }

    @Test
    void basicSettingsCheck() {
        def loggerMockContext = new MockFor(Logger)
        loggerMockContext.ignore(~".*") {}
        def loggerMock = loggerMockContext.proxyInstance([null])
        def simpleSettingsYaml = '''\
        settings:
            ubuntu:
                version: trusty
            docker:
                image: shadowrobot/build-tools
                tag: trusty-indigo
            ros:
                release: indigo
            toolset:
                template_job_name: my_template
                modules:
                    - check_cache
                    - code_coverage'''
        def config = new Settings(simpleSettingsYaml, loggerMock)
        checkBasicSettings(config)

        def configForBranch = new Settings(simpleSettingsYaml, loggerMock, "my_super_feature")
        checkBasicSettings(configForBranch)

        def configForTrunk = new Settings(simpleSettingsYaml, loggerMock, "kinetic-devel")
        checkBasicSettings(configForTrunk)
    }
}
