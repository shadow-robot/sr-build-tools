import org.junit.Test
import org.junit.BeforeClass
import groovy.mock.interceptor.*

class RepositoryTest {
    static Logger loggerMock
    static Map credentialsMock
    static Settings settingsMock

    @BeforeClass
    static void initializeMocks() {

        credentialsMock = [username: " ",
                           password: " ",
                           token: " "]

        def loggerMockContext = new MockFor(Logger)
        loggerMockContext.ignore(~".*") {}
        loggerMock = loggerMockContext.proxyInstance([null])

        def settingsMockContext = new StubFor(Settings)
        settingsMockContext.ignore.with{
            getSettings() {[ros:[release:'mock']]}
            getStatus() {Settings.Status.GOOD}
        }
        settingsMock = settingsMockContext.proxyInstance([[:], loggerMock] as Object[])
    }

    def generateBranchMock(boolean isTrunk = true, int numOfSettings = 2) {
        def testRepository = new GithubRepository("mockOrganisation", "mockName", credentialsMock, loggerMock)
        def settingsArray = []
        for (int i = 0; i < numOfSettings; i++) {
            settingsArray.push(settingsMock)
        }

        def branchMockContext = new StubFor(Branch)
        branchMockContext.ignore('asBoolean')
        branchMockContext.ignore.with{
            getLogger()
            getName()
            getRepository()
            getTrunk() {isTrunk}
            getHead() {!isTrunk}
            getSettings() {settingsArray}
        }
        def branchMock = branchMockContext.proxyInstance(["mockName", "mockSha", testRepository] as Object[])

        return branchMock
    }

    @Test
    void getSettingsFromFileTestSingleSettings() {
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
                      tag: xenial-kinetic

        branch:
            parent: kinetic-devel'''

        def testRepository = new GithubRepository("mockOrganisation", "mockName", credentialsMock, loggerMock)
        testRepository.metaClass.getFileContents = {String filePath, String branchName -> onlyTrunksSettingsYaml}

        def testSettings = testRepository.getSettingsFromFile("mock", "kinetic-devel")
        assert testSettings.size() == 1

        assert "xenial" == testSettings[0].settings.ubuntu.version
        assert "kinetic" == testSettings[0].settings.ros.release
        assert "xenial-kinetic" == testSettings[0].settings.docker.tag
    }

    @Test
    void getSettingsFromFileTestMultipleSettings() {
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
    void generateJobsTestOnlyBranches() {
        def testRepository = new GithubRepository("mockOrganisation", "mockName", credentialsMock, loggerMock)
        def branchMockTrunk = generateBranchMock(true, 2)
        def branchMockHead = generateBranchMock(false, 3)

        testRepository.branches = new ArrayList<Branch>()
        testRepository.branches.push(branchMockTrunk)
        testRepository.branches.push(branchMockHead)

        testRepository.generateJobs(settingsMock)
        assert 5 == testRepository.jobs.size()
    }

    @Test
    void generateJobsTestOnlyPRs() {
        def testRepository = new GithubRepository("mockOrganisation", "mockName", credentialsMock, loggerMock)
        def branchMockTrunk = generateBranchMock(true, 2)
        def prMock = new PullRequest(1, " ")
        prMock.branch = branchMockTrunk

        testRepository.pullRequests = new ArrayList<PullRequest>()
        testRepository.pullRequests.push(prMock)
        testRepository.pullRequests.push(prMock)

        testRepository.generateJobs(settingsMock)
        assert 4 == testRepository.jobs.size()
    }

    @Test
    void generateJobsTestBranchesAndPRs() {
        def testRepository = new GithubRepository("mockOrganisation", "mockName", credentialsMock, loggerMock)
        def branchMockTrunk = generateBranchMock(true, 2)
        def branchMockHead = generateBranchMock(false, 3)
        def prMock = new PullRequest(1, " ")
        prMock.branch = branchMockTrunk

        testRepository.branches = new ArrayList<Branch>()
        testRepository.branches.push(branchMockTrunk)
        testRepository.branches.push(branchMockHead)
        testRepository.pullRequests = new ArrayList<PullRequest>()
        testRepository.pullRequests.push(prMock)

        testRepository.generateJobs(settingsMock)
        assert 7 == testRepository.jobs.size()
    }
}