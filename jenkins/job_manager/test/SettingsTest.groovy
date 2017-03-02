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
                image: shadowrobot/build-tools
                tag: trusty-indigo
            ros:
                release: indigo
            toolset:
                template_job_name: my_template
                modules:
                    - check_cache
                    - code_coverage'''
        def config = new Settings(simpleSettingsYaml, loggerMock)

        assert "trusty" == config.settings.ubuntu.version
        assert "shadowrobot/build-tools" == config.settings.docker.image
        assert "trusty-indigo" == config.settings.docker.tag
        assert "indigo" == config.settings.ros.release
        assert "my_template" == config.settings.toolset.template_job_name
        assert 2 == config.settings.toolset.modules.size()
//        assert "check_cache" in config.settings.toolset.modules
//        assert "code_coverage" in config.settings.toolset.modules
    }
}
