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

from launchpadlib.launchpad import Launchpad
import subprocess, shlex

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




class LaunchpadMergeProposalReviewer(object):
    """
    Interfaces with launchpad to get the available merge proposals.
    """

    def __init__(self, team = "shadowrobot", cachedir = "~/.launchpadlib/cache"):
        """
        This will get all the merge proposal associated to the shadowrobot team.
        """
        self.bzr_utils = BzrUtils()

        self.launchpad = Launchpad.login_with('Merge Proposal Reviewer', 'production', cachedir, credential_save_failed = self.no_credential)
        self.team = self.launchpad.people( team )

        self.merge_proposals = None

    def no_credential(self):
        print "Can't proceed without Launchpad credential."
        sys.exit()

    def get_active_merge_proposals(self):
        """
        Returns a list containing the different active merge proposals. Includes the full diff for each of those.

        a merge proposal has the following elements: address, all_comments_collection_link, commit_message, date_created,
                                                     date_merged, date_queued, date_review_requested, date_reviewed,
                                                     description, http_etag, merge_reporter_link, merged_revno, prerequisite_branch_link,
                                                     preview_diff_link, private, queue_position, queue_status, queued_revid, queuer_link,
                                                     registrant_link, resource_type_link, reviewed_revid, reviewer_link, self_link,
                                                     source_branch_link, superseded_by_link, supersedes_link, target_branch_link, votes_collection_link,
                                                     web_link, full_diff

        @return the interesting element of each merge proposal are probably "full_diff", "commit_message"
        """
        self.merge_proposals = self.team.getMergeProposals(status='Needs review')

        for index,entry in enumerate(self.merge_proposals.entries):
            target = self.bzr_utils.launchpadify(entry["target_branch_link"])
            source = self.bzr_utils.launchpadify(entry["source_branch_link"])

            print "Comparing "+ target + " and: " + source

            bzr_diff = self.bzr_utils.diff(target, source)

            self.merge_proposals.entries[index]["target_branch_link"] = target
            self.merge_proposals.entries[index]["source_branch_link"] = source
            self.merge_proposals.entries[index]["full_diff"] = bzr_diff

        return self.merge_proposals.entries


def main():
    lp = LaunchpadMergeProposalReviewer()
    mp = lp.get_active_merge_proposals()

    for i,m in enumerate(mp):
        #print m

        f = open("/tmp/toto_" + str(i), 'w')
        f.writelines(m["full_diff"])
        f.close()

if __name__ == '__main__':
    main()

