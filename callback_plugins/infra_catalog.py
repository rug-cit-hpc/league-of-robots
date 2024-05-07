from __future__ import annotations

DOCUMENTATION = '''
    name: infra_catalog
    type: stdout
    short_description: Custom output for Infra Catalog
    version_added: N/A
    description:
        - This is the default output for the infra_catalog.yml play
    extends_documentation_fragment:
      - result_format_callback
'''

from ansible.plugins.callback import CallbackBase
from ansible.plugins.callback import strip_internal_keys, module_response_deepcopy
from ansible import constants as ANSIBLE_CONSTANTS
from ansible.module_utils.common.text.converters import to_text
from ansible.parsing.yaml.dumper import AnsibleDumper

import yaml
import json
import re
import string
import textwrap
#import logging, sys
#logging.basicConfig(stream=sys.stderr, level=logging.DEBUG)

# from http://stackoverflow.com/a/15423007/115478
def should_use_block(value):
    """Returns true if string should be in block format"""
    for c in u"\u000a\u000d\u001c\u001d\u001e\u0085\u2028\u2029":
        if c in value:
            return True
    return False


class MyDumper(AnsibleDumper):
    def represent_scalar(self, tag, value, style=None):
        """Uses block style for multi-line strings"""
        #logging.debug('YAML Style = %s', style)
        if style is None:
            if should_use_block(value):
                style = '|'
                # we care more about readable than accuracy, so...
                # ...no trailing space
                value = value.rstrip()
                # ...and non-printable characters
                value = ''.join(x for x in value if x in string.printable or ord(x) >= 0xA0)
                # ...tabs prevent blocks from expanding
                value = value.expandtabs()
                # ...and odd bits of whitespace
                value = re.sub(r'[\x0b\x0c\r]', '', value)
                # ...as does trailing space
                value = re.sub(r' +\n', '\n', value)
            else:
                style = self.default_style
        node = yaml.representer.ScalarNode(tag, value, style=style)
        if self.alias_key is not None:
            self.represented_objects[self.alias_key] = node
        return node

class CallbackModule(CallbackBase):

    CALLBACK_VERSION = 1.0
    CALLBACK_TYPE = 'stdout'
    CALLBACK_NAME = 'infra_catalog'

    def _command_generic_msg(self, host, result, caption):
        ''' output the result of a command run '''

        buf = "%s | %s | rc=%s >>\n" % (host, caption, result.get('rc', -1))
        buf += result.get('stdout', '')
        buf += result.get('stderr', '')
        buf += result.get('msg', '')

        return buf + "\n"

    def _dump_results(self, result, indent=None, sort_keys=True, keep_invocation=False):
        if result.get('_ansible_no_log', False):
            return json.dumps(dict(censored="The output has been hidden due to the fact that 'no_log: true' was specified for this result"))

        # All result keys stating with _ansible_ are internal, so remove them from the result before we output anything.
        abridged_result = strip_internal_keys(module_response_deepcopy(result))

        # remove invocation unless specifically wanting it
        if not keep_invocation and self._display.verbosity < 3 and 'invocation' in result:
            del abridged_result['invocation']

        # remove diff information from screen output
        if self._display.verbosity < 3 and 'diff' in result:
            del abridged_result['diff']

        # remove exception from screen output
        if 'exception' in abridged_result:
            del abridged_result['exception']

        dumped = ''

        # put changed and skipped into a header line
        if 'changed' in abridged_result:
            dumped += 'changed=' + str(abridged_result['changed']).lower() + ' '
            del abridged_result['changed']

        if 'skipped' in abridged_result:
            dumped += 'skipped=' + str(abridged_result['skipped']).lower() + ' '
            del abridged_result['skipped']

        # if we already have stdout, we don't need stdout_lines
        if 'stdout' in abridged_result and 'stdout_lines' in abridged_result:
            abridged_result['stdout_lines'] = '<omitted>'

        # if we already have stderr, we don't need stderr_lines
        if 'stderr' in abridged_result and 'stderr_lines' in abridged_result:
            abridged_result['stderr_lines'] = '<omitted>'

        if abridged_result:
            dumped += to_text(yaml.dump(abridged_result['msg'], allow_unicode=True, width=1000, Dumper=MyDumper, default_flow_style=False))
            dumped = re.sub(r'[ ]*\|-[ ]*\n', '', dumped)

        if indent is not None:
            dumped = textwrap.indent(dumped, indent * ' ')

        return dumped

    def _serialize_diff(self, diff):
        return to_text(yaml.dump(diff, allow_unicode=True, width=1000, Dumper=AnsibleDumper, default_flow_style=False))

    def v2_runner_on_failed(self, result, ignore_errors=False):

        self._handle_exception(result._result)
        self._handle_warnings(result._result)

        if result._task.action in ANSIBLE_CONSTANTS.MODULE_NO_JSON and 'module_stderr' not in result._result:
            self._display.display(self._command_generic_msg(result._host.get_name(), result._result, "FAILED"), color=ANSIBLE_CONSTANTS.COLOR_ERROR)
        else:
            self._display.display("%s | FAILED! => %s" % (result._host.get_name(), self._dump_results(result._result, indent=4)), color=ANSIBLE_CONSTANTS.COLOR_ERROR)

    def v2_runner_on_ok(self, result):
        self._clean_results(result._result, result._task.action)

        self._handle_warnings(result._result)

        if result._result.get('changed', False):
            color = ANSIBLE_CONSTANTS.COLOR_CHANGED
            state = 'CHANGED'
        else:
            color = ANSIBLE_CONSTANTS.COLOR_OK
            state = 'SUCCESS'

        if result._task.action in ANSIBLE_CONSTANTS.MODULE_NO_JSON and 'ansible_job_id' not in result._result:
            self._display.display(self._command_generic_msg(result._host.get_name(), result._result, state), color=color)
        else:
            self._display.display("%s:\n%s" % (result._host.get_name(), self._dump_results(result._result, indent=4)), color=color)

    def v2_runner_on_skipped(self, result):
        #
        # Do not display skipped hosts
        #
        #self._display.display("%s | SKIPPED" % (result._host.get_name()), color=ANSIBLE_CONSTANTS.COLOR_SKIP)
        pass

    def v2_runner_on_unreachable(self, result):
        #
        # Do not display skipped hosts
        #
        #self._display.display("%s | UNREACHABLE! => %s" % (result._host.get_name(), self._dump_results(result._result, indent=4)), color=ANSIBLE_CONSTANTS.COLOR_UNREACHABLE)
        pass

    def v2_on_file_diff(self, result):
        if 'diff' in result._result and result._result['diff']:
            self._display.display(self._get_diff(result._result['diff']))

