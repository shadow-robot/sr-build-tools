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
if not ansible.callbacks.original_display:
    ansible.callbacks.original_display = ansible.callbacks.display
ansible.callbacks.display = dummy_display
