import org.junit.Test
import static org.mockito.Mockito.mock

class SettingsTest {

    @Test
    void basicSettingsCheck() {
        def loggerMock = mock(Logger.class)
        def simpleSettingsYaml = '''\
        settings:
            ubuntu:
                version: trusty
            docker:
                image: shadowrobot/ramcip
                tag: main
            ros:
                release: indigo
            toolset:
                template_job_name: my_template
            modules:
                - check_cache
                - code_coverage'''
        def settings = new Settings(simpleSettingsYaml, loggerMock)

        assert "my_template" == settings.settings.toolset.template_job_name
    }

    @Test
    void indexOutOfBoundsAccess() {
        def numbers = [1,2,3,4,5]
        shouldFail {
            numbers.get(4)
        }
    }

}
