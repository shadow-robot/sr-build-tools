#!/usr/bin/env python
#
# Copyright 2011 Shadow Robot Company Ltd.
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program.  If not, see <http://www.gnu.org/licenses/>.
#


import subprocess, shlex, os, sys, tempfile, optparse
import pickle
from launchpadlib.launchpad import Launchpad
import rbtools.postreview
from rbtools.postreview import ReviewBoardServer
from rbtools.clients import SCMClient, RepositoryInfo

class BzrUtils(object):
    """
    A set of usefull functions for bzr.
    """

    def __init__(self, ):
        """
        """
        pass

    def diff(self, target, source):
        """
        Returns the diff between the 2 specified urls: runs bzr diff --old source --new target
        """
        command = "bzr diff --old " + target + " --new " + source
        command = shlex.split(str(command))
        process = subprocess.Popen(command , shell=False, stdout = subprocess.PIPE)
        output = process.communicate()
        diff = output[0]
        if diff != None and diff.strip() == '':
            diff = None
        return diff

    def launchpadify(self, url):
        """
        Modifies the given url to have the form: lp:~shadowrobot/...

        @url: the url is typically u'https://api.staging.launchpad.net/1.0/~shadowrobot/project-name/branch-name'
        """
        launchpad_url = "lp:~shadowrobot"
        splitted_url = url.split("shadowrobot")
        launchpad_url += splitted_url[-1]
        return launchpad_url
    
    def httpify(self, url):
        """
        Modifies the given url to have the form: http:~shadowrobot/...
        These are needed for review board as that doesn't handle lp: urls
        (which are generally a real pain for automation).

        @url: the url is typically u'https://api.staging.launchpad.net/1.0/~shadowrobot/project-name/branch-name'
        """
        http_url = "http://bazaar.launchpad.net/~shadowrobot"
        splitted_url = url.split("shadowrobot")
        http_url += splitted_url[-1]
        return http_url


class LaunchpadMergeProposalReviewer(object):
    """
    Interfaces with launchpad to get the available merge proposals.
    """

    def __init__(self, team = "shadowrobot", cachedir = "~/.launchpadlib/cache"):
        """
        This will get all the merge proposal associated to the shadowrobot team.
        """
        self.bzr_utils = BzrUtils()

        self.launchpad = Launchpad.login_with(
                'Merge Proposal Reviewer', 'production', cachedir,
                credential_save_failed = self.no_credential)
        self.team = self.launchpad.people( team )

        self.merge_proposals = None

    def no_credential(self):
        print "Can't proceed without Launchpad credential."
        sys.exit()

    def get_active_merge_proposals(self):
        """
        Returns a list containing the different active merge proposals.
        Includes the full diff for each of those.

        A merge proposal has the following elements: address,
            all_comments_collection_link, commit_message, date_created,
            date_merged, date_queued, date_review_requested, date_reviewed,
            description, http_etag, merge_reporter_link, merged_revno,
            prerequisite_branch_link, preview_diff_link, private, queue_position,
            queue_status, queued_revid, queuer_link, registrant_link,
            resource_type_link, reviewed_revid, reviewer_link, self_link,
            source_branch_link, superseded_by_link, supersedes_link,
            target_branch_link, votes_collection_link, web_link, full_diff

        In addition we add:
            target_branch_lp, target_branch_http, source_branch_lp,
            source_branch_http

        @return the interesting element of each merge proposal are probably
        "full_diff", "commit_message"
        """
        self.merge_proposals = self.team.getMergeProposals(status='Needs review')

        for index,entry in enumerate(self.merge_proposals.entries):
            target = self.bzr_utils.launchpadify(entry["target_branch_link"])
            source = self.bzr_utils.launchpadify(entry["source_branch_link"])
            print "Comparing "+ target + " and: " + source
            bzr_diff = self.bzr_utils.diff(target, source)

            entry["target_branch_lp"] = target
            entry["source_branch_lp"] = source
            entry["target_branch_http"] = self.bzr_utils.httpify(
                    entry["target_branch_link"])
            entry["source_branch_http"] = self.bzr_utils.httpify(
                    entry["source_branch_link"])
            entry["full_diff"] = bzr_diff
            if entry["commit_message"] == None:
                entry["commit_message"] = ""

        return self.merge_proposals.entries


class CmdError(Exception):
    def __init__(self,msg,status=23):
        self.msg    = msg
        self.status = status
    def __str__(self):
        return self.msg


class LPMerge2RB(object):
    def __init__(self):
        self.server   = "http://reviewboard.shadow.local"
        self.username = 'mark'
        self.password = 'shadow'
        self.lp       = None
        self.mp       = None

    def run(self):
        self.lp = LaunchpadMergeProposalReviewer()
        self.mp = self.lp.get_active_merge_proposals()
        #pickle.dump(self.mp, open("./mp.out", 'w'))
        #self.mp = pickle.load(open("./mp.out", 'r'))
        for m in self.mp:
            self.post_review(m)
        return 0

    def post_review(self, m):
        """
        Based on main() from rbtools.postreview. Lets us post a diff without
        a checkout. Bit like:
         post-review --repository=foo --diff-file=foo.diff
        """
        if not self.server:
            raise CmdError("No server url");
        if len(m['full_diff']) == 0:
            raise CmdError("There don't seem to be any diffs!")
        
        desc = (m['description']
                + "\n\nCommit Message:\n" + m['commit_message']
                + "\n\nLP Link:\n" + m['web_link'] )

        # postreview uses a global options all through its classes. grrr. So we
        # have to fix that up here.
        rbtools.postreview.parse_options([
                '--server', self.server,
                '--username', self.username,
                '--password', self.password,
                '--debug',
                '--repository', m['target_branch_http'],
                '--description', desc
            ])
        
        # Not in a repo so fake up the info
        repository_info = RepositoryInfo(
                path=m['target_branch_http'],
                base_path="/",    # Diffs are always relative to the root.
                supports_parent_diffs=False )

        # If we end up creating a cookie file, make sure it's only readable by the
        # user.
        os.umask(0077)
        cookie_file = os.path.join(os.environ["HOME"], ".post-review-cookies.txt")
        server = ReviewBoardServer(self.server, repository_info, cookie_file)

        # Handle the case where /api/ requires authorization (RBCommons).
        if not server.check_api_version():
            raise CmdError("Unable to log in with the supplied username and password.")

        diff = m['full_diff']
        parent_diff = None
        submit_as   = None
        tool        = SCMClient() 
        changenum   = None

        # Post the review 
        server.login()
        review_url = rbtools.postreview.tempt_fate(
                server, tool, changenum, diff_content=diff,
                parent_diff_content=parent_diff,
                submit_as=submit_as)


if __name__ == '__main__':
    sys.exit( LPMerge2RB().run() )
