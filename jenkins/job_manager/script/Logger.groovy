class Logger {
    enum Verbosity {
        DEBUG, INFO, WARN, ERROR, FATAL
    }
    Verbosity verbosity
    def output

    Logger(output, verbosity = Verbosity.WARN) {
        this.output = output
        this.verbosity = verbosity
    }

    def log(String message, Verbosity verbosity = this.verbosity) {
        if (verbosity >= this.verbosity) {
            output.println("[${new Date().getTimeString()}] [${verbosity}] ${message}")
        }
    }

    def debug(String message) {
        log(message, Verbosity.DEBUG)
    }

    def info(String message) {
        log(message, Verbosity.INFO)
    }

    def warn(String message) {
        log(message, Verbosity.WARN)
    }

    def error(String message) {
        log(message, Verbosity.ERROR)
    }

    def fatal(String message) {
        log(message, Verbosity.FATAL)
    }
}
