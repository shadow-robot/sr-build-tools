#!/usr/bin/env python
"""
See README.md
"""
from __future__ import absolute_import
import json
from threading import Timer
from ansible.plugins.callback import CallbackBase


def fixed_dump_results(self, result, indent=None, sort_keys=True, keep_invocation=False):
    json_message = self._original_dump_results(result, indent, sort_keys, keep_invocation)
    message_dictionary = json.loads(json_message, encoding="utf-8")
    result = ""
    for key, value in message_dictionary.iteritems():
        if key not in ["stderr", "stdout_lines"]:
            result = result + "  " + key + " => " + unicode(value) + "\n"

    if "stderr" in message_dictionary and len(unicode(message_dictionary["stderr"])) > 0:
        result = result + "\nvvvvvvvv  STDERR  vvvvvvvvv\n\n  stderr => " + unicode(message_dictionary["stderr"])
    return result


# Monkey patch to turn off default callback logging
CallbackBase._original_dump_results = CallbackBase._dump_results
CallbackBase._dump_results = fixed_dump_results


class CallbackModule(CallbackBase):

    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'beautifier'
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
