import org.junit.Test
import org.junit.BeforeClass
import groovy.mock.interceptor.*

class RepositoryTest {
    static Logger loggerMock
    static Map credentialsMock

    @BeforeClass
    static void initializeMocks() {
        credentialsMock = [username: " ",
                           password: " ",
                           token: " "]

        def loggerMockContext = new MockFor(Logger)
        loggerMockContext.ignore(~".*") {}
        loggerMock = loggerMockContext.proxyInstance([null])
    }

    @Test
    void getSettingsFromFileTest(){
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
                        tag: willy-kinetic
        branch:
            parent: kinetic-devel'''

        def testRepository = new GithubRepository("mockOrganisation", "mockName", credentialsMock, loggerMock)
        testRepository.metaClass.getFileContents = {String filePath, String branchName -> onlyTrunksMultipleSettingsYaml}

        def testSettings = testRepository.getSettingsFromFile("mock", "kinetic-devel")
        assert testSettings.size() == 2

        assert "xenial" == testSettings[0].settings.ubuntu.version
        assert "kinetic" == testSettings[0].settings.ros.release
        assert "xenial-kinetic" == testSettings[0].settings.docker.tag

        assert "willy" == testSettings[1].settings.ubuntu.version
        assert "kinetic" == testSettings[1].settings.ros.release
        assert "willy-kinetic" == testSettings[1].settings.docker.tag
    }
}