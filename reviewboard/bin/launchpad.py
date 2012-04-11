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


import subprocess, shlex, os, sys, tempfile, optparse, urlparse
import pickle
import datetime
from launchpadlib.launchpad import Launchpad
import rbtools.postreview
from rbtools.postreview import ReviewBoardServer
from rbtools.clients import SCMClient, RepositoryInfo
from rbtools.api.errors import APIError

# Monkey patch a new_repository method as current rbtools doesn't supply one.
def new_repository_monkey(self, name, path, tool = "Bazaar"):
    repos = self.get_repositories()
    for repo in repos:
        if repo['tool'] == tool and repo['path'] == path:
            # Repo exists no need to create it
            return repo

    # Not found so create
    data = { 'name': name, 'tool': tool, 'path': path }
    rbtools.postreview.debug("Attempting to create repo %s " % data)

    if self.deprecated_api:
        #rsp = self.api_post('api/json/reviewrequests/new/', data)
        raise Exception("TODO old style api")
    else:
        links = self.root_resource['links']
        assert 'repositories' in links
        href = links['repositories']['href']
        rsp = self.api_post(href, data)

    rbtools.postreview.debug("Created repo %s " % rsp['repository'])
    return rsp['repository']

ReviewBoardServer.new_repository = new_repository_monkey


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
        # TODO: This doesn't seem to generate the same diff as the merge.
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
            merge_reporter_user, registrant_user, reviewer_user

        @return the interesting element of each merge proposal are probably
        "full_diff", "commit_message"
        """
        self.merge_proposals = self.team.getMergeProposals(status='Needs review')

        for index,entry in enumerate(self.merge_proposals.entries):
            # Get the object returned via the api (entities just gives us dicts)
            mp = self.merge_proposals[index]

            target = self.bzr_utils.launchpadify(entry["target_branch_link"])
            source = self.bzr_utils.launchpadify(entry["source_branch_link"])
            bzr_diff = "".join( mp.preview_diff.diff_text.open().readlines() )

            entry["target_branch_lp"] = target
            entry["source_branch_lp"] = source
            entry["target_branch_http"] = self.bzr_utils.httpify(
                    entry["target_branch_link"])
            entry["source_branch_http"] = self.bzr_utils.httpify(
                    entry["source_branch_link"])
            entry["full_diff"] = bzr_diff
            for l in ("merge_reporter", "registrant", "reviewer"):
                if entry[l+"_link"] == None: entry[l+"_user"] = None
                else: entry[l+"_user"] = self._link_user_name(entry[l+"_link"])
            if entry["commit_message"] == None:
                entry["commit_message"] = ""

            # Find the reviewers
            reviewer_users = []
            reviewer_teams = []
            for vote in mp.votes:
                name = self._link_user_name(vote.reviewer.self_link)
                if vote.reviewer.is_team:
                    reviewer_teams.append(name)
                else:
                    reviewer_users.append(name)
            entry['voted_reviewer_users'] = reviewer_users
            entry['voted_reviewer_teams'] = reviewer_teams

        return self.merge_proposals.entries

    def _link_user_name(self, link):
        """
        Give a LP url for a user e.g.
          u'merge_reporter_link': u'https://api.launchpad.net/1.0/~toliver-shadow'
        Return the user name only ie name after ~, toliver-shadow
        """
        path = link.split('/')
        if len(path) < 1: return None
        if path[-1][0] != '~': return None 
        return path[-1][1:] 


class CmdError(Exception):
    def __init__(self,msg,status=23):
        self.msg    = msg
        self.status = status
    def __str__(self):
        return self.msg


class LPMerge2RB(object):
    def __init__(self):
        self.server   = "http://reviewboard.shadow.local"
        # This rb user needs perms to create and mod requests as other users
        self.username = 'admin'
        self.password = 'shadow'
        self.lp       = None
        self.mp       = None
        self.history_file  = './lpmerge2rb.hist'
        self.history  = None

    def run(self):
        self.load_history()
        self.lp = LaunchpadMergeProposalReviewer()
        self.mp = self.lp.get_active_merge_proposals()
        #pickle.dump(self.mp, open("./mp.out", 'w'))
        #self.mp = pickle.load(open("./mp.out", 'r'))
        #import pprint
        #pp = pprint.PrettyPrinter(indent=4)
        #print(pp.pprint(self.mp))
        #sys.exit(0)

        #for m in [self.mp[0]]:
        for m in self.mp:
            print("Found: "+ m['web_link'])
            try:
                h = self.find_history(m['self_link'])
                if h:
                    print("Already processed, skipping. %s" % h['review_url'])
                else:
                    review_url = self.post_review(m)
                    self.add_history(m, review_url)
                    print("Added review: %s"%review_url);
            except (APIError, CmdError) as err:
                sys.stderr.write("Error: %s"%err);

        self.save_history()
        return 0

    def load_history(self):
        if self.history: return
        if not os.path.exists(self.history_file):
            self.history = {}
        else:
            self.history = pickle.load(open(self.history_file))

    def save_history(self):
        pickle.dump(self.history, open(self.history_file, 'w'))

    def add_history(self, m, rb_url):
        # According to lp docs web_link can be used as identifier
        self.history[m['self_link']] = {
                    'review_url': rb_url,
                    'self_link': m['self_link'],
                    'added': datetime.datetime.today()
                }

    def find_history(self, self_link):
        if self_link in self.history:
            return self.history[self_link]
        return None

    def post_review(self, m):
        """
        Based on main() from rbtools.postreview. Lets us post a diff without
        a checkout. Bit like: post-review --repository=foo --diff-file=foo.diff
        """
        if not self.server:
            raise CmdError("No server url");
        if len(m['full_diff']) == 0:
            raise CmdError("There don't seem to be any diffs!")
        
        repo_url = m['target_branch_http']
        summary = "Merge "+m['source_branch_lp']+" into "+m['target_branch_lp']
        # Create a description a bit like the merge page on lp site
        desc = ("Link: " + m['web_link']
                + "\n\nProposed branch: " + m['source_branch_lp']
                + "\nMerge into: " + m['target_branch_lp']
                + "\n\nDescription:\n" + m['description']
                + "\n\nCommit Message:\n" + m['commit_message']
                )

        # postreview uses a global options all through its classes. grrr. So we
        # have to fix that up here.
        cmd_args = [
                '--server', self.server,
                '--username', self.username,
                '--password', self.password,
                '--debug',
                '--repository', repo_url,
                '--summary', summary,
                '--description', desc,
            ]

        # The users must already exists with matching name in rb
        if m['voted_reviewer_users']:
            cmd_args.extend([ '--target-people', ','.join(m['voted_reviewer_users']) ])
        # Map teams to rb groups, which need to be setup with matching name in rb
        if m['voted_reviewer_teams']:
            cmd_args.extend([ '--target-groups', ','.join(m['voted_reviewer_teams']) ])
        if m['voted_reviewer_users'] or m['voted_reviewer_teams']:
            cmd_args.append('--publish')

        rbtools.postreview.parse_options(cmd_args)
        
        # Not in a repo so fake up the info
        repository_info = RepositoryInfo(
                path=repo_url,
                base_path="/",    # Diffs are always relative to the root.
                supports_parent_diffs=False )

        # If we end up creating a cookie file, make sure it's only readable by the
        # user.
        os.umask(0077)
        cookie_file = os.path.join(os.environ["HOME"], ".post-review-cookies.txt")
        self.rb = ReviewBoardServer(self.server, repository_info, cookie_file)

        # Handle the case where /api/ requires authorization (RBCommons).
        # This is needed to initialise the object before making API calls.
        if not self.rb.check_api_version():
            raise CmdError("Unable to log in with the supplied username and password.")
        self.rb.login()

        # Make sure the repo is there
        url  = urlparse.urlsplit(repo_url)
        path = url.path.split('/')
        if len(path) < 2:
            raise("Repo url '%s' too short" % repo_url)
        repo_name = path[-2] + "-" + path[-1]
        self.rb.new_repository(repo_name, repo_url, tool="Bazaar")

        # Post the review 
        diff = m['full_diff']
        parent_diff = None
        submit_as   = m['registrant_user']
        tool        = SCMClient() 
        changenum   = None
        review_url = rbtools.postreview.tempt_fate(
                self.rb, tool, changenum, diff_content=diff,
                parent_diff_content=parent_diff,
                submit_as=submit_as)

        return review_url


if __name__ == '__main__':
    sys.exit( LPMerge2RB().run() )
