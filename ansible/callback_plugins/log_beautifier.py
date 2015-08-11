#!/usr/bin/env python
"""
See README.md
"""

import ansible.callbacks

def dummy_display(msg, color=None, stderr=False, screen_only=False,
                  log_only=False, runner=None):
    modified_message = msg.replace("\\n", "\n")
    ansible.callbacks.original_display(modified_message, color=color,
                                       stderr=stderr, screen_only=screen_only,
                                       log_only=log_only, runner=runner)

# Monkey patch to turn off default callback logging
if hasattr(ansible.callbacks, 'original_display'):
    ansible.callbacks.original_display = ansible.callbacks.display
ansible.callbacks.display = dummy_display

class CallbackModule(object):

    def on_any(self, *args, **kwargs):
        pass

    def runner_on_failed(self, host, res, ignore_errors=False):
        pass

    def runner_on_ok(self, host, res):
        pass

    def runner_on_error(self, host, msg):
        pass

    def runner_on_skipped(self, host, item=None):
        pass

    def runner_on_unreachable(self, host, res):
        pass

    def runner_on_no_hosts(self):
        pass

    def runner_on_async_poll(self, host, res, jid, clock):
        pass

    def runner_on_async_ok(self, host, res, jid):
        pass

    def runner_on_async_failed(self, host, res, jid):
        pass

    def playbook_on_start(self):
        pass

    def playbook_on_notify(self, host, handler):
        pass

    def playbook_on_no_hosts_matched(self):
        pass

    def playbook_on_no_hosts_remaining(self):
        pass

    def playbook_on_task_start(self, name, is_conditional):
        pass

    def playbook_on_vars_prompt(self, varname, private=True, prompt=None,
                                encrypt=None, confirm=False,
                                salt_size=None, salt=None, default=None):
        pass

    def playbook_on_setup(self):
        pass

    def playbook_on_import_for_host(self, host, imported_file):
        pass

    def playbook_on_not_import_for_host(self, host, missing_file):
        pass

    def playbook_on_play_start(self, pattern):
        pass

    def playbook_on_stats(self, stats):
        pass
