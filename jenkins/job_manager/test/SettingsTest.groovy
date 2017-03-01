import org.junit.Test
import static groovy.test.GroovyAssert.shouldFail

class SettingsTest {

    @Test
    void indexOutOfBoundsAccess() {
        def numbers = [1,2,3,4,5]
        shouldFail {
            numbers.get(4)
        }
    }

}
