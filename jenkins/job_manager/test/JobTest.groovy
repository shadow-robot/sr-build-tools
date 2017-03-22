import org.junit.Test
import org.junit.BeforeClass
import groovy.mock.interceptor.MockFor

class JobTest{

    static Branch branchMock
    static Repository repositoryMock

    @BeforeClass
    static void initializeMocks() {
        branchMock = new MockFor(Branch)
        repositoryMock = new MockFor(Repository)
    }

    @Test
    void dummyTest(){
        assert 1==1
    }

}