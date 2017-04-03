import org.junit.Test
import org.junit.BeforeClass
import groovy.mock.interceptor.*

class RepositoryTest {
    static Logger loggerMock
    static Map credentialsMock
    static Settings settingsMock
    static Branch branchMock

    @BeforeClass
    static void initializeMocks() {

        credentialsMock = [username: " ",
                           password: " ",
                           token: " "]

        def loggerMockContext = new MockFor(Logger)
        loggerMockContext.ignore(~".*") {}
        loggerMock = loggerMockContext.proxyInstance([null])

        def settingsMockContext = new StubFor(Settings)
        settingsMockContext.demand.with{
            getStatus(1..8) {Settings.Status.GOOD}
            getSettings(1..4){[ros:[release:'mock']]}
        }
        settingsMock = settingsMockContext.proxyInstance([[:], loggerMock] as Object[])
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

    @Test
    void generateJobsTest(){
        def testRepository = new GithubRepository("mockOrganisation", "mockName", credentialsMock, loggerMock)

        def branchMockContext = new StubFor(Branch)
        branchMockContext.ignore('getLogger')
        branchMockContext.ignore('getName')
        branchMockContext.ignore('getRepository')
        branchMockContext.demand.with{
            getTrunk(1..10) {true}
            getSettings(1..16) {[settingsMock, settingsMock]}
        }
        branchMock = branchMockContext.proxyInstance(["mockName", "mockSha", testRepository] as Object[])

        testRepository.branches = new ArrayList<Branch>()
        testRepository.branches.push(branchMock)
        testRepository.branches.push(branchMock)

        testRepository.generateJobs(settingsMock)
        assert 4 == testRepository.jobs.size()
    }
}