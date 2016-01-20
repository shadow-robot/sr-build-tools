#!/usr/bin/env python
"""
See README.md
"""

from threading import Lock
from threading import Timer
from ansible.utils.display import Display
from ansible.plugins.callback import CallbackBase


def fixed_display(self, msg, color=None, stderr=False, screen_only=False, log_only=False):
    if not hasattr(self, "_display_lock"):
        self._display_lock = Lock()
        self._previous_msg = ""
        self._previous_color = None
        self._previous_stderr = False
        self._previous_screen_only = False
        self._previous_log_only = False

    with self._display_lock:
        try:
            modified_message = msg.decode('string-escape')
        except UnicodeDecodeError:
            modified_message = msg.encode('utf-8').decode('unicode_escape')

        if self._previous_msg.startswith("stderr: ") and msg.startswith("stdout: "):
            self._original_display(modified_message, color=color, stderr=stderr, screen_only=screen_only,
                                   log_only=log_only)
            self._previous_msg = "\nvvvvvvvv  STDERR  vvvvvvvvv\n\n" + self._previous_msg
        else:
            self._original_display(self._previous_msg, self._previous_color, self._previous_stderr,
                                   self._previous_screen_only, self._previous_log_only)
            self._previous_msg = modified_message
            self._previous_color = color
            self._previous_stderr = stderr
            self._previous_screen_only = screen_only
            self._previous_log_only = log_only


# Monkey patch to turn off default callback logging
Display._original_display = Display.display
Display.display = fixed_display


class CallbackModule(CallbackBase):

    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'stdout'
    CALLBACK_NAME = 'long_running_operation_status'

    def __init__(self, display=None):
        super(CallbackModule, self).__init__(display=display)
        self.__timer_interval = 20.0
        self.__progress_timer = Timer(self.__timer_interval, self.__in_progress_message)

    def __in_progress_message(self):
        self._display.display('status: ["operation in progress..."]', color='yellow')
        self.__progress_timer = Timer(self.__timer_interval, self.__in_progress_message)
        self.__progress_timer.start()

    def v2_playbook_on_task_start(self, task, is_conditional):
        self.__progress_timer.cancel()
        self.__progress_timer = Timer(self.__timer_interval, self.__in_progress_message)
        self.__progress_timer.start()

    def v2_playbook_on_stats(self, stats):
        self.__progress_timer.cancel()

        # Pushing last message to output if any in queue
        self._display.display("")
