import org.junit.Test
import org.junit.BeforeClass
import groovy.mock.interceptor.MockFor

class JobTest{

    static Branch branchMock
    static Repository repositoryMock
    static Logger loggerMock

    @BeforeClass
    static void initializeMocks() {
        def credentials = [username: "jenkins_username",
                           password: "jenkins_password",
                           token: "jenkins_token"]

        def loggerMockContext = new MockFor(Logger)
        loggerMockContext.ignore(~".*") {}
        loggerMock = loggerMockContext.proxyInstance([null])

       // def branchMockContext = new MockFor(Branch)
        def repositoryMockContext = new MockFor(Repository)
        def argList = ["a", "b", null, loggerMock]
        repositoryMock = repositoryMockContext.proxyInstance(["a", "b", credentials, loggerMock] as Object[])
       // println repositoryMock.name
    }

    @Test
    void dummyTest(){
        assert 1==1
    }

}