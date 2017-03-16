class PullRequest {
    Integer index
    String sha
    Branch branch

    PullRequest(Integer index, String sha) {
        this.index = index
        this.sha = sha
    }

    String toString() {
        return "${index}${branch ? '(' + branch.name + ')' : ''})"
    }
}
