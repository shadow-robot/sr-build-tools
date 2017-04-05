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

    void checkKineticTrunkWilly(Settings config) {
        assert "willy" == config.settings.ubuntu.version
        assert "shadowrobot/build-tools" == config.settings.docker.image
        assert "willy-kinetic" == config.settings.docker.tag
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

        def settingsParserDefault = new SettingsParser(simpleSettingsYaml, loggerMock)
        assert 1 == settingsParserDefault.settingsList.size()
        def configDefault = settingsParserDefault.settingsList.get(0)
        checkBasicSettings(configDefault)

        def settingsParserBranch = new SettingsParser(simpleSettingsYaml, loggerMock, "my_super_feature")
        assert 1 == settingsParserBranch.settingsList.size()
        def configForBranch = settingsParserBranch.settingsList.get(0)
        checkBasicSettings(configForBranch)

        def settingsParserTrunk = new SettingsParser(simpleSettingsYaml, loggerMock, "kinetic-devel")
        assert 1 == settingsParserTrunk.settingsList.size()
        def configForTrunk = settingsParserTrunk.settingsList.get(0)
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

        def settingsParserDefault = new SettingsParser(onlyTrunksSettingsYaml, loggerMock)
        assert 1 == settingsParserDefault.settingsList.size()
        def configDefault = settingsParserDefault.settingsList.get(0)
        checkBasicSettings(configDefault)

        def settingsParserBranch = new SettingsParser(onlyTrunksSettingsYaml, loggerMock, "my_super_feature")
        assert 1 == settingsParserBranch.settingsList.size()
        def configForBranch = settingsParserBranch.settingsList.get(0)
        checkBasicSettings(configForBranch)

        def settingsParserIndigoTrunk = new SettingsParser(onlyTrunksSettingsYaml, loggerMock, "indigo-devel")
        assert 1 == settingsParserIndigoTrunk.settingsList.size()
        def configForIndigoTrunk = settingsParserIndigoTrunk.settingsList.get(0)
        checkBasicSettings(configForIndigoTrunk)

        def settingsParserKineticTrunk = new SettingsParser(onlyTrunksSettingsYaml, loggerMock, "kinetic-devel")
        assert 1 == settingsParserKineticTrunk.settingsList.size()
        def configForKineticTrunk = settingsParserKineticTrunk.settingsList.get(0)
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

        def settingsParserDefault = new SettingsParser(branchInheritedSettingsYaml, loggerMock)
        assert 1 == settingsParserDefault.settingsList.size()
        def configDefault = settingsParserDefault.settingsList.get(0)
        checkBasicSettings(configDefault)

        def settingsParserBranch = new SettingsParser(branchInheritedSettingsYaml, loggerMock, "my_kinetic_branch")
        assert 1 == settingsParserBranch.settingsList.size()
        def configForBranch = settingsParserBranch.settingsList.get(0)
        checkKineticTrunkSettings(configForBranch)

        def settingsParserIndigoTrunk = new SettingsParser(branchInheritedSettingsYaml, loggerMock, "indigo-devel")
        assert 1 == settingsParserIndigoTrunk.settingsList.size()
        def configForIndigoTrunk = settingsParserIndigoTrunk.settingsList.get(0)
        checkBasicSettings(configForIndigoTrunk)

        def settingsParserKineticTrunk = new SettingsParser(branchInheritedSettingsYaml, loggerMock, "kinetic-devel")
        assert 1 == settingsParserKineticTrunk.settingsList.size()
        def configForKineticTrunk = settingsParserKineticTrunk.settingsList.get(0)
        checkKineticTrunkSettings(configForKineticTrunk)
    }

    @Test
    void onlyTrunksMultipleSettings() {
        def onlyTrunksMultipleSettingsYaml = '''\
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
                  - ubuntu:
                        version: xenial
                    ros:
                        release: kinetic
                    docker:
                        tag: xenial-kinetic
                  - ubuntu:
                        version: willy
                    ros:
                        release: kinetic
                    docker:
                        tag: willy-kinetic'''

        def settingsParserDefault = new SettingsParser(onlyTrunksMultipleSettingsYaml, loggerMock)
        assert 1 == settingsParserDefault.settingsList.size()
        def configDefault = settingsParserDefault.settingsList.get(0)
        checkBasicSettings(configDefault)

        def settingsParserBranch = new SettingsParser(onlyTrunksMultipleSettingsYaml, loggerMock, "my_super_feature")
        assert 1 == settingsParserBranch.settingsList.size()
        def configForBranch = settingsParserBranch.settingsList.get(0)
        checkBasicSettings(configForBranch)

        def settingsParserIndigoTrunk = new SettingsParser(onlyTrunksMultipleSettingsYaml, loggerMock, "indigo-devel")
        assert 1 == settingsParserIndigoTrunk.settingsList.size()
        def configForIndigoTrunk = settingsParserIndigoTrunk.settingsList.get(0)
        checkBasicSettings(configForIndigoTrunk)

        def settingsParserKineticTrunk = new SettingsParser(onlyTrunksMultipleSettingsYaml, loggerMock, "kinetic-devel")
        assert 2 == settingsParserKineticTrunk.settingsList.size()
        checkKineticTrunkSettings(settingsParserKineticTrunk.settingsList.get(0))
        checkKineticTrunkWilly(settingsParserKineticTrunk.settingsList.get(1))
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
                  - ubuntu:
                        version: xenial
                    ros:
                        release: kinetic
                    docker:
                        tag: xenial-kinetic
                  - ubuntu:
                        version: willy
                    ros:
                        release: kinetic
                    docker:
                        tag: willy-kinetic
        branch:
            parent: kinetic-devel'''

        def settingsParserDefault = new SettingsParser(branchInheritedMultipleSettingsYaml, loggerMock)
        assert 1 == settingsParserDefault.settingsList.size()
        def configDefault = settingsParserDefault.settingsList.get(0)
        checkBasicSettings(configDefault)

        def settingsParserIndigoTrunk = new SettingsParser(branchInheritedMultipleSettingsYaml, loggerMock, "indigo-devel")
        assert 1 == settingsParserIndigoTrunk.settingsList.size()
        def configForIndigoTrunk = settingsParserIndigoTrunk.settingsList.get(0)
        checkBasicSettings(configForIndigoTrunk)

        def settingsParserBranch = new SettingsParser(branchInheritedMultipleSettingsYaml, loggerMock, "my_kinetic_branch")
        assert 2 == settingsParserBranch.settingsList.size()
        checkKineticTrunkSettings(settingsParserBranch.settingsList.get(0))
        checkKineticTrunkWilly(settingsParserBranch.settingsList.get(1))

        def settingsParserKineticTrunk = new SettingsParser(branchInheritedMultipleSettingsYaml, loggerMock, "kinetic-devel")
        assert 2 == settingsParserKineticTrunk.settingsList.size()
        checkKineticTrunkSettings(settingsParserKineticTrunk.settingsList.get(0))
        checkKineticTrunkWilly(settingsParserKineticTrunk.settingsList.get(1))
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

        def settingsParserDefault = new SettingsParser(branchOverridesModulesListSettingsYaml, loggerMock)
        assert 1 == settingsParserDefault.settingsList.size()
        def configDefault = settingsParserDefault.settingsList.get(0)
        checkBasicSettings(configDefault)

        def settingsForBranch = new SettingsParser(branchOverridesModulesListSettingsYaml, loggerMock, "my_new_kinetic_branch")
        assert 1 == settingsForBranch.settingsList.size()
        def configForBranch = settingsForBranch.settingsList.get(0)

        assert "xenial" == configForBranch.settings.ubuntu.version
        assert "xenial-kinetic" == configForBranch.settings.docker.tag
        assert "kinetic" == configForBranch.settings.ros.release
        assert 2 == configForBranch.settings.toolset.modules.size()
        assert "check_cache" in configForBranch.settings.toolset.modules
        assert "software_tests" in configForBranch.settings.toolset.modules

        def settingsForIndigoTrunk = new SettingsParser(branchOverridesModulesListSettingsYaml, loggerMock, "indigo-devel")
        assert 1 == settingsForIndigoTrunk.settingsList.size()
        def configForIndigoTrunk = settingsForIndigoTrunk.settingsList.get(0)
        checkBasicSettings(configForIndigoTrunk)

        def settingsForKineticTrunk = new SettingsParser(branchOverridesModulesListSettingsYaml, loggerMock, "kinetic-devel")
        assert 1 == settingsForKineticTrunk.settingsList.size()
        def configForKineticTrunk = settingsForKineticTrunk.settingsList.get(0)

        assert "xenial" == configForKineticTrunk.settings.ubuntu.version
        assert "xenial-kinetic" == configForKineticTrunk.settings.docker.tag
        assert "kinetic" == configForKineticTrunk.settings.ros.release
        assert 2 == configForKineticTrunk.settings.toolset.modules.size()
        assert "check_cache" in configForKineticTrunk.settings.toolset.modules
        assert "all_tests" in configForKineticTrunk.settings.toolset.modules

    }

    @Test
    void checkBranchMultipleBranchSettings() {
        def MultipleBranchSettingsYaml = '''\
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
            - name: super-new-version-devel
              settings:
                  - ubuntu:
                        version: xenial
                    ros:
                        release: kinetic
                    docker:
                        tag: xenial-kinetic
                  - ubuntu:
                        version: willy
                    ros:
                        release: kinetic
                    docker:
                        tag: willy-kinetic
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

        def settingsParserDefault = new SettingsParser(MultipleBranchSettingsYaml, loggerMock)
        assert 1 == settingsParserDefault.settingsList.size()
        def configDefault = settingsParserDefault.settingsList.get(0)
        checkBasicSettings(configDefault)

        def settingsParserBranch = new SettingsParser(MultipleBranchSettingsYaml, loggerMock, "my_kinetic_branch")
        assert 1 == settingsParserBranch.settingsList.size()
        def configForBranch = settingsParserBranch.settingsList.get(0)
        checkKineticTrunkSettings(configForBranch)

        def settingsParserNewTrunk = new SettingsParser(MultipleBranchSettingsYaml, loggerMock, "super-new-version-devel")
        assert 2 == settingsParserNewTrunk.settingsList.size()
        checkKineticTrunkSettings(settingsParserNewTrunk.settingsList.get(0))
        checkKineticTrunkWilly(settingsParserNewTrunk.settingsList.get(1))

        def settingsParserKineticTrunk = new SettingsParser(MultipleBranchSettingsYaml, loggerMock, "kinetic-devel")
        assert 1 == settingsParserKineticTrunk.settingsList.size()
        checkKineticTrunkSettings(settingsParserKineticTrunk.settingsList.get(0))
    }

    @Test
    void checkBranchMultipleToolsets() {
        def branchMultipleToolsetsYaml = '''\
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
            - name: new-version-devel
            - name: kinetic-devel
              settings:
                  ubuntu:
                      version: xenial
                  ros:
                      release: kinetic
                  docker:
                      tag: xenial-kinetic

        branch:
            parent: new-version-devel
            settings:
                - toolset:
                      modules:
                          - check_cache
                          - software_tests
                - toolset:
                      template_job_name: my_second_template
                      modules:
                        - code_style_check'''

        def settingsParserDefault = new SettingsParser(branchMultipleToolsetsYaml, loggerMock)
        assert 1 == settingsParserDefault.settingsList.size()
        def configDefault = settingsParserDefault.settingsList.get(0)
        checkBasicSettings(configDefault)

        def settingsForBranch = new SettingsParser(branchMultipleToolsetsYaml, loggerMock, "my_new_version_branch")
        assert 2 == settingsForBranch.settingsList.size()

        def configForBranch0 = settingsForBranch.settingsList.get(0)

        assert "trusty" == configForBranch0.settings.ubuntu.version
        assert "trusty-indigo" == configForBranch0.settings.docker.tag
        assert "indigo" == configForBranch0.settings.ros.release
        assert 2 == configForBranch0.settings.toolset.modules.size()
        assert "check_cache" in configForBranch0.settings.toolset.modules
        assert "software_tests" in configForBranch0.settings.toolset.modules

        def configForBranch1 = settingsForBranch.settingsList.get(1)

        assert "trusty" == configForBranch1.settings.ubuntu.version
        assert "trusty-indigo" == configForBranch1.settings.docker.tag
        assert "indigo" == configForBranch1.settings.ros.release
        assert 1 == configForBranch1.settings.toolset.modules.size()
        assert "code_style_check" in configForBranch1.settings.toolset.modules


        def settingsForKineticTrunk = new SettingsParser(branchMultipleToolsetsYaml, loggerMock, "kinetic-devel")
        assert 1 == settingsForKineticTrunk.settingsList.size()
        def configForKineticTrunk = settingsForKineticTrunk.settingsList.get(0)

        assert "xenial" == configForKineticTrunk.settings.ubuntu.version
        assert "xenial-kinetic" == configForKineticTrunk.settings.docker.tag
        assert "kinetic" == configForKineticTrunk.settings.ros.release
        assert 2 == configForKineticTrunk.settings.toolset.modules.size()
        assert "check_cache" in configForKineticTrunk.settings.toolset.modules
        assert "code_coverage" in configForKineticTrunk.settings.toolset.modules
    }

    @Test
    void checkBranchMultipleToolsets2() {
        def branchMultipleToolsetsYaml = '''\
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
            parent: indigo-devel
            settings:
                - toolset:
                      modules:
                          - check_cache
                - toolset:
                      template_job_name: template_unit_tests_and_code_coverage
                      modules:
                          - code_coverage'''

        def settingsParserDefault = new SettingsParser(branchMultipleToolsetsYaml, loggerMock)
        assert 1 == settingsParserDefault.settingsList.size()
        def configDefault = settingsParserDefault.settingsList.get(0)
        checkBasicSettings(configDefault)

        def settingsForBranch = new SettingsParser(branchMultipleToolsetsYaml, loggerMock, "my_new_version_branch")
        assert 2 == settingsForBranch.settingsList.size()

        def configForBranch0 = settingsForBranch.settingsList.get(0)

        assert "trusty" == configForBranch0.settings.ubuntu.version
        assert "trusty-indigo" == configForBranch0.settings.docker.tag
        assert "indigo" == configForBranch0.settings.ros.release
        assert 1 == configForBranch0.settings.toolset.modules.size()
        assert "check_cache" in configForBranch0.settings.toolset.modules

        def configForBranch1 = settingsForBranch.settingsList.get(1)

        assert "trusty" == configForBranch1.settings.ubuntu.version
        assert "trusty-indigo" == configForBranch1.settings.docker.tag
        assert "indigo" == configForBranch1.settings.ros.release
        assert 1 == configForBranch1.settings.toolset.modules.size()
        assert "code_coverage" in configForBranch1.settings.toolset.modules

    }
}