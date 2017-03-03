import org.junit.Test
import org.junit.BeforeClass
import groovy.mock.interceptor.MockFor

class SettingsTest {

    static Logger loggerMock

    @BeforeClass
    void initializeMocks() {
        def loggerMockContext = new MockFor(Logger)
        loggerMockContext.ignore(~".*") {}
        loggerMock = loggerMockContext.proxyInstance([null])
    }

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

    void checkKineticTrunkSettings(Settings config) {
        assert "xenial" == config.settings.ubuntu.version
        assert "shadowrobot/build-tools" == config.settings.docker.image
        assert "xenial-kinetic" == config.settings.docker.tag
        assert "kinetic" == config.settings.ros.release
        assert "my_template" == config.settings.toolset.template_job_name
        assert 2 == config.settings.toolset.modules.size()
        assert "check_cache" in config.settings.toolset.modules
        assert "code_coverage" in config.settings.toolset.modules
    }

    @Test
    void basicSettingsCheck() {
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
        def configDefault = new Settings(simpleSettingsYaml, loggerMock)
        checkBasicSettings(configDefault)

        def configForBranch = new Settings(simpleSettingsYaml, loggerMock, "my_super_feature")
        checkBasicSettings(configForBranch)

        def configForTrunk = new Settings(simpleSettingsYaml, loggerMock, "kinetic-devel")
        checkBasicSettings(configForTrunk)
    }

    @Test
    void onlyTrunksConfiguration() {
        def onlyTrunksSettingsYaml = '''\
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
                    - code_coverage

        trunks:
            - name: indigo-devel
            - name: kinetic-devel
                settings:
                ubuntu:
                    version: xenial
                ros:
                    release: kinetic
                docker:
                    tag: xenial-kinetic'''

        def configDefault = new Settings(simpleSettingsYaml, loggerMock)
        checkBasicSettings(configDefault)

        def configForBranch = new Settings(simpleSettingsYaml, loggerMock, "my_new_branch")
        checkBasicSettings(configForBranch)

        def configForIndigoTrunk = new Settings(simpleSettingsYaml, loggerMock, "indigo-devel")
        checkBasicSettings(configForIndigoTrunk)

        def configForKineticTrunk = new Settings(simpleSettingsYaml, loggerMock, "kinetic-devel")
        checkKineticTrunkSettings(configForKineticTrunk)
    }
}
