#!/usr/bin/env python
"""
See README.md
"""

import ansible.callbacks
from threading import Lock
from threading import Timer

ansible.callbacks.display_lock = Lock()


def dummy_display(msg, color=None, stderr=False, screen_only=False,
                  log_only=False, runner=None):

    with ansible.callbacks.display_lock:

        if not hasattr(dummy_display, "previous_msg"):
            dummy_display.previous_msg = ""
            dummy_display.previous_color = None
            dummy_display.previous_stderr = False
            dummy_display.previous_screen_only = False
            dummy_display.previous_log_only = False
            dummy_display.previous_runner = None

        modified_message = msg.encode('utf-8').decode('unicode_escape')

        if (dummy_display.previous_msg.startswith("stderr: ") and
                msg.startswith("stdout: ")):
            ansible.callbacks.original_display(
                modified_message,
                color=color, stderr=stderr, screen_only=screen_only,
                log_only=log_only, runner=runner)
            dummy_display.previous_msg = ("\n vvvvvvvvvvvvvvvvvvvvvvvvvvvvvv" +
                                         dummy_display.previous_msg)
        else:
            ansible.callbacks.original_display(
                dummy_display.previous_msg, dummy_display.previous_color,
                dummy_display.previous_stderr,
                dummy_display.previous_screen_only,
                dummy_display.previous_log_only, dummy_display.previous_runner)
            dummy_display.previous_msg = modified_message
            dummy_display.previous_color = None
            dummy_display.previous_stderr = False
            dummy_display.previous_screen_only = False
            dummy_display.previous_log_only = False
            dummy_display.previous_runner = None


# Monkey patch to turn off default callback logging
if not hasattr(ansible.callbacks, 'original_display'):
    ansible.callbacks.original_display = ansible.callbacks.display
ansible.callbacks.display = dummy_display


class CallbackModule(object):

    def __init__(self):
        self.timer_interval = 20.0
        self.progress_timer = Timer(self.timer_interval,
                                    self.in_progress_message)

    def in_progress_message(self):
        ansible.callbacks.display('status: ["operation in progress..."]',
                                  color='yellow')
        self.progress_timer = Timer(self.timer_interval,
                                    self.in_progress_message)
        self.progress_timer.start()

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
        self.progress_timer.cancel()
        self.progress_timer = Timer(self.timer_interval,
                                    self.in_progress_message)
        self.progress_timer.start()

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
        self.progress_timer.cancel()

        # Pushing last message to output if any in queue
        ansible.callbacks.display("")
