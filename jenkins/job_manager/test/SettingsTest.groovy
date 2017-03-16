import org.junit.Test
import org.junit.BeforeClass
import groovy.mock.interceptor.MockFor

class SettingsTest {

    static Logger loggerMock

    @BeforeClass
    static void initializeMocks() {
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

    void checkKineticTrunkMultipleSettings(Settings config) {
        assert 2 == config.settings.ubuntu.version.size()
        assert "xenial" in config.settings.ubuntu.version
        assert "willy" in config.settings.ubuntu.version
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

        def configDefault = new Settings(onlyTrunksSettingsYaml, loggerMock)
        checkBasicSettings(configDefault)

        def configForBranch = new Settings(onlyTrunksSettingsYaml, loggerMock, "my_new_branch")
        checkBasicSettings(configForBranch)

        def configForIndigoTrunk = new Settings(onlyTrunksSettingsYaml, loggerMock, "indigo-devel")
        checkBasicSettings(configForIndigoTrunk)

        def configForKineticTrunk = new Settings(onlyTrunksSettingsYaml, loggerMock, "kinetic-devel")
        checkKineticTrunkSettings(configForKineticTrunk)
    }

    @Test
    void checkBranchInheritedSettings() {
        def branchInheritedSettingsYaml = '''\
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
                      tag: xenial-kinetic
        branch:
            parent: kinetic-devel'''

        def configDefault = new Settings(branchInheritedSettingsYaml, loggerMock)
        checkBasicSettings(configDefault)

        def configForBranch = new Settings(branchInheritedSettingsYaml, loggerMock, "my_kinetic_branch")
        checkKineticTrunkSettings(configForBranch)

        def configForIndigoTrunk = new Settings(branchInheritedSettingsYaml, loggerMock, "indigo-devel")
        checkBasicSettings(configForIndigoTrunk)

        def configForKineticTrunk = new Settings(branchInheritedSettingsYaml, loggerMock, "kinetic-devel")
        checkKineticTrunkSettings(configForKineticTrunk)
    }

    @Test
    void checkBranchInheritedMultipleSettings() {
        def branchInheritedMultipleSettingsYaml = '''\
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
                      tag: xenial-kinetic
        branch:
            parent: kinetic-devel'''

        def configDefault = new Settings(branchInheritedMultipleSettingsYaml, loggerMock)
        checkBasicSettings(configDefault)

        def configForBranch = new Settings(branchInheritedMultipleSettingsYaml, loggerMock, "my_kinetic_branch")
        checkKineticTrunkMultipleSettings(configForBranch)

        def configForIndigoTrunk = new Settings(branchInheritedMultipleSettingsYaml, loggerMock, "indigo-devel")
        checkBasicSettings(configForIndigoTrunk)

        def configForKineticTrunk = new Settings(branchInheritedMultipleSettingsYaml, loggerMock, "kinetic-devel")
        checkKineticTrunkMultipleSettings(configForKineticTrunk)
    }

    @Test
    void checkModulesListOverride() {
        def branchOverridesModulesListSettingsYaml = '''\
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
                      tag: xenial-kinetic
                  toolset:
                      modules:
                          - check_cache
                          - all_tests
        branch:
            parent: kinetic-devel
            settings:
                toolset:
                    modules:
                        - check_cache
                        - software_tests'''

        def configDefault = new Settings(branchOverridesModulesListSettingsYaml, loggerMock)
        checkBasicSettings(configDefault)

        def configForBranch = new Settings(branchOverridesModulesListSettingsYaml, loggerMock, "my_new_kinetic_branch")
        assert "xenial" == configForBranch.settings.ubuntu.version
        assert "xenial-kinetic" == configForBranch.settings.docker.tag
        assert "kinetic" == configForBranch.settings.ros.release
        assert 2 == configForBranch.settings.toolset.modules.size()
        assert "check_cache" in configForBranch.settings.toolset.modules
        assert "software_tests" in configForBranch.settings.toolset.modules

        def configForIndigoTrunk = new Settings(branchOverridesModulesListSettingsYaml, loggerMock, "indigo-devel")
        checkBasicSettings(configForIndigoTrunk)

        def configForKineticTrunk = new Settings(branchOverridesModulesListSettingsYaml, loggerMock, "kinetic-devel")
        assert "xenial" == configForKineticTrunk.settings.ubuntu.version
        assert "xenial-kinetic" == configForKineticTrunk.settings.docker.tag
        assert "kinetic" == configForKineticTrunk.settings.ros.release
        assert 2 == configForKineticTrunk.settings.toolset.modules.size()
        assert "check_cache" in configForKineticTrunk.settings.toolset.modules
        assert "all_tests" in configForKineticTrunk.settings.toolset.modules
    }
}