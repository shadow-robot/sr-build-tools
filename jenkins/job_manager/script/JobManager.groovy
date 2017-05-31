import jenkins.model.Jenkins
import hudson.plugins.git.browser.GithubWeb
import javax.xml.transform.stream.StreamSource
import java.util.regex.Pattern

class JobManager {
    String[] githubRepoNames
    Logger logger
    Settings defaultSettings
    def credentials, jenkinsInstance, currentJenkinsJobs
    ArrayList<Repository> repositories = new ArrayList<Repository>()

    JobManager(credentials, Logger logger, ArrayList<String> githubRepoNames, jenkinsInstance) {
        this.logger = logger
        this.credentials = credentials
        this.githubRepoNames = githubRepoNames
        this.jenkinsInstance = jenkinsInstance
        logger.info("Job manager created.")
    }

    def processJobs() {
        logger.info("Processing jobs...")
        fetchCurrentJenkinsJobs()
        def newAutoJobs = repositories.jobs.flatten()
        def goodNewAutoJobs = newAutoJobs.findAll { it.settings.status != Settings.Status.ERROR }
        def newJobsWithBranchConfigs = goodNewAutoJobs.findAll { it.settings.source == Settings.Source.BRANCH }
        def newJobsWithTrunkConfigs = goodNewAutoJobs.findAll { it.settings.source == Settings.Source.TRUNK }
        def newJobsWithDefaultConfigs = goodNewAutoJobs.findAll { it.settings.source == Settings.Source.DEFAULT }
        logger.info("Parsing repository branches resulted in ${newAutoJobs.size()} jobs:")
        logger.debug("${newAutoJobs*.name}")
        logger.info("${newJobsWithBranchConfigs.size()} jobs for branches containing a valid jenkins.yml")
        logger.debug("${newJobsWithBranchConfigs*.name}")
        logger.info("${newJobsWithTrunkConfigs.size()} jobs for branches that use the main branch jenkins.yml")
        logger.debug("${newJobsWithTrunkConfigs*.name}")
        logger.info("${newJobsWithDefaultConfigs.size()} jobs for branches that use the default jenkins.yml")
        logger.debug("${newJobsWithDefaultConfigs*.name}")
        logger.debug("${newJobsWithDefaultConfigs*.settings}")
        def jobsToMake = new ArrayList<Job>(goodNewAutoJobs)
        def jobsToKeep = new ArrayList<>()
        def jobsToDelete = new ArrayList<>(currentJenkinsJobs)

        // If any of the new jobs match names with the current jobs, keep the job, and don't make a new one
        currentJenkinsJobs.each { currentJenkinsJob ->
            goodNewAutoJobs.each { goodNewAutoJob ->
                if (currentJenkinsJob.name == goodNewAutoJob.name) {
                    jobsToDelete.remove(currentJenkinsJob)
                    jobsToKeep.add(goodNewAutoJob)
                    jobsToMake.remove(goodNewAutoJob)
                }
            }
        }
        logger.info("${jobsToKeep.size()} of the existing auto jobs will be preserved because they have the same name as a newly generated job.")
        logger.debug("${jobsToKeep*.name}")

        // Also keep any jobs that look like they might correspond to a repository for which I failed to get branches
        // or pull requests. Note that an empty list of pull requests is OK, an uninitialised list is not.
        def erroredRepositories = repositories.findAll { it.branches == null || it.pullRequests == null }
        if (erroredRepositories) {
            logger.warn("Due to errors obtaining branch or pull request information for the following repositories:")
            logger.warn("${erroredRepositories*.name}")
            logger.warn("It is possible some jobs will mistakenly not be created.")
            ArrayList<String> errorRepoJobNameStarts = new ArrayList<String>()
            erroredRepositories.each { repository ->
                errorRepoJobNameStarts.push("auto_${repository.name}_")
            }
            logger.warn("Existing jobs with names beginning with any of the following will be preserved:")
            logger.warn("${errorRepoJobNameStarts}")
            def jobsToKeepDueToRepoErrors = jobsToDelete.findAll { job ->
                errorRepoJobNameStarts.any { name ->
                    job.name.startsWith(name)
                }
            }
            if (jobsToKeepDueToRepoErrors) {
                logger.warn("Specifically, these jobs will be preserved:")
                logger.warn("${jobsToKeepDueToRepoErrors*.name}")
                jobsToDelete.removeAll(jobsToKeepDueToRepoErrors)
                jobsToKeep.addAll(jobsToKeepDueToRepoErrors)
            } else {
                logger.warn("There are no existing jobs that seem to match repositories with errors.")
            }
        } else {
            logger.info("There were no errors fetching branch or pull request information.")
        }

        // Also keep any jobs that look like they might correspond to a branch that I failed to get config for this time
        def errorNewAutoJobs = newAutoJobs.findAll { it.settings.status == Settings.Status.ERROR }
        if (errorNewAutoJobs) {
            logger.warn("There are ${errorNewAutoJobs.size()} new jobs for which I failed to fetch a jenkins.yml with an unknown error:")
            logger.warn("${errorNewAutoJobs*.name}")
            ArrayList<String> errorBranchJobNameStarts = new ArrayList<String>()
            errorNewAutoJobs.each { job ->
                errorBranchJobNameStarts.push("auto_${job.repository.name}_${job.branch.name}_")
            }
            logger.warn("Existing jobs with names beginning with any of the following will be preserved:")
            logger.warn("${errorBranchJobNameStarts}")
            def jobsToKeepDueToBranchErrors = jobsToDelete.findAll { currentJob ->
                errorBranchJobNameStarts.any { name ->
                    currentJob.name.startsWith(name)
                }
            }
            if (jobsToKeepDueToBranchErrors) {
                logger.warn("Specifically, these jobs will be preserved:")
                logger.warn("${jobsToKeepDueToBranchErrors*.name}")
                jobsToDelete.removeAll(jobsToKeepDueToBranchErrors)
                jobsToKeep.addAll(jobsToKeepDueToBranchErrors)
            } else {
                logger.warn("There are no existing jobs that seem to match branches with jenkins.yml errors.")
            }
        } else {
            logger.info("There were no errors fetching branches' jenkins.yml")
        }

        deleteJobs(jobsToDelete)
        makeNewJobs(jobsToMake)
        refreshExistingJobs(jobsToKeep)
    }

    def makeNewJobs(jobs) {
        logger.info("Making ${jobs.size()} new jobs")
        logger.info("${jobs*.name}")
        jobs.each { makeJob(it) }
    }

    def refreshExistingJobs(jobs) {
        logger.info("Refreshing ${jobs.size()} existing jobs")
        logger.info("${jobs*.name}")
        jobs.each { makeJob(it, false) }
    }

    def deleteJobs(jobs) {
        logger.info("Deleting ${jobs.size()} current jobs")
        jobs.each { deleteJob(it) }
    }

    def fetchDefaultSettings() {
        logger.info("Fetching default job settings...")
        def defaultSettingsRepository = new GithubRepository('shadow-robot', 'sr-build-tools', credentials, logger)
        def defaultSettingsList = defaultSettingsRepository.getSettingsFromFile('config/default_jenkins.yml', 'master')
        defaultSettings = defaultSettingsList.get(0)
        if (!defaultSettings) {
            logger.info("Failed to obtain default settings. Aborting.")
            return false
        }
        defaultSettings.source = Settings.Source.DEFAULT
        true
    }

    def initialiseRepositories() {
        logger.info("Initialising repositories...")
        repositories.addAll(githubRepoNames.collect { new GithubRepository('shadow-robot', it, credentials, logger) })
    }

    def processRepositories() {
        logger.info("Processing repositories...")
        if (!fetchDefaultSettings()) return false
        initialiseRepositories()
        repositories.each { repository ->
            repository.process(defaultSettings)
        }
        return true
    }

    def fetchCurrentJenkinsJobs() {
        logger.info("Getting current Jenkins \"auto_\" jobs...")
        this.currentJenkinsJobs = jenkinsInstance.projects.findAll { it.name.startsWith("auto_") }
        logger.info("There are currently ${currentJenkinsJobs.size()} \"auto\" jobs.")
    }

    def deleteJob(job) {
        logger.info("Deleting job: ${job.name}")
        job.delete()
    }

    def makeJob(job, boolean generateNew=true) {
        if (job instanceof hudson.model.Job) {
            return
        }  
        if (job.getClass() != Job) {
            throw new Exception("Job should be either our internal class or already existing Jenkins class, but it's not. Please check why is it so.")
        }
        def template = Jenkins.instance.getItem(job.settings.settings.toolset.template_job_name)
        if (!(template instanceof hudson.model.Job)) {
            logger.error("Could not find template job \'${job.settings.settings.toolset.template_job_name}\'")
            return false
        }

        def existingJob = Jenkins.instance.projects.find { it.name == job.name }
        def newJob = null
        if (generateNew) {
            if (existingJob instanceof hudson.model.Job) {
                logger.error("${job.name} already exists.")
                return false
            }
            logger.info("Creating new Jenkins job: ${job.name}...")
            logger.debug("${job.settings}")
            newJob = Jenkins.instance.copy(template, job.name)
        }
        else {
            if (null == existingJob) {
                logger.error("${job.name} doesn't exist but want to be refreshed.")
                return false
            }
            newJob = existingJob
            def jobXmlFile = template.getConfigFile()
            def file = jobXmlFile.getFile()
            newJob.updateByXml(new StreamSource(new FileInputStream(file)))
        }

        newJob.description = "Job for ${job.branch.name} branch of ${job.repository.url}, based on template " +
                "${template.name} using ros release ${job.settings.settings.ros.release}"
        newJob.disabled = false
        def property = newJob.properties.find {
            it.key.getClass().getName().startsWith("com.coravy.hudson.plugins.github.GithubProjectProperty")
        }
        property.value.projectUrl = job.repository.url
        newJob.scm.browser = new GithubWeb(job.repository.url)
        newJob.scm.userRemoteConfigs[0].url = "${job.repository.url}.git"
        if (job.branch.head || job.branch.trunk) {
            newJob.scm.userRemoteConfigs[0].refspec = ""
            newJob.scm.branches[0].name = "**/" + job.branch.name
        } else {
            newJob.scm.branches[0].name = "**/pr/${job.branch.pullRequests[0].index}/head"
            newJob.scm.userRemoteConfigs[0].refspec = "+refs/pull/*:refs/remotes/origin/pr/*"
        }
        def dockerTask = newJob.builders.find {
            it.hasProperty("command") && it.command != null && it.command.contains("{{docker_image_name}}")
        }
        if (null != dockerTask) {
            def realCommand = dockerTask.command.replaceAll(Pattern.quote("{{docker_image_name}}"), "${job.settings.settings.docker.image}:${job.settings.settings.docker.tag}")
            realCommand = realCommand.replaceAll(Pattern.quote("{{modules_list}}"), job.settings.settings.toolset.modules.join(','))
            realCommand = realCommand.replaceAll(Pattern.quote("{{ros_release}}"), job.settings.settings.ros.release)
            realCommand = realCommand.replaceAll(Pattern.quote("{{ubuntu_version}}"), job.settings.settings.ubuntu.version)
            def builders = newJob.buildersList
            def oldBuilders = builders.toList()
            builders.clear()
            for (item in oldBuilders) {
                if (item == dockerTask) {
                    builders.add(new hudson.tasks.Shell(realCommand))
                } else {
                    builders.add(item)
                }
            }
        }
        newJob.save()
        def jobXmlFile = newJob.getConfigFile()
        def file = jobXmlFile.getFile()
        newJob.updateByXml(new StreamSource(new FileInputStream(file)))
        newJob.save()
        if (generateNew) {
            logger.info("Created new Jenkins job: ${job.name}")
        }
        else {
            logger.info("Refreshed existing Jenkins job: ${job.name}")
        }
        return newJob.name
    }
}
