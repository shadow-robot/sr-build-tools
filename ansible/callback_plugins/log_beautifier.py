#!/usr/bin/env python

# Copyright 2022 Shadow Robot Company Ltd.
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

"""
See README.md
"""
import json
import re
from threading import Timer
from ansible.plugins.callback import CallbackBase


def obfuscate_credentials(input_value):
    return re.sub("https://(.*?)@github.com", "https://*****:*****@github.com", input_value)


def fixed_dump_results(self, result, indent=None, sort_keys=True, keep_invocation=False):
    json_message = self._original_dump_results(result, indent, sort_keys, keep_invocation)  # pylint: disable=W0212
    message_dictionary = json.loads(json_message, encoding="utf-8")
    result = ""
    for key, value in message_dictionary.items():
        if key not in ["stderr", "stdout_lines"]:
            result = result + "  " + key + " => " + obfuscate_credentials(str(value)) + "\n"

    if "stderr" in message_dictionary and len(str(message_dictionary["stderr"])) > 0:
        result = result + "\nvvvvvvvv  STDERR  vvvvvvvvv\n\n  stderr => " + \
            obfuscate_credentials(str(message_dictionary["stderr"]))
    return result


class CallbackModule(CallbackBase):

    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'beautifier'
    CALLBACK_NAME = 'long_running_operation_status'

    # Monkey patch to turn off default callback logging
    CallbackBase._original_dump_results = CallbackBase._dump_results
    CallbackBase._dump_results = fixed_dump_results

    def __init__(self, display=None):
        super().__init__(display=display)
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
