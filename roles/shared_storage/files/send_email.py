#!/usr/bin/env python

#
# Helper script to send mail using the Isilon libraries.
# Original from: https://groups.google.com/g/isilon-user-group/c/4XM0_hmHTr0/m/sRos52H2HAAJ
#

import sys
from optparse import OptionParser
import socket
from isi.app.lib.emailer import Emailer, EmailAttachmentFromFile

# Emailer.send_email(to_addresses(list), message(string), from_address=None(string),  subject=None(string),
#                    attachments=None(list), headers=None(list), charset="us-ascii"(string))

def main():
	usage = '%prog: [-f sender] -t recipient [ -t recipient ... ] [-s subject] [-b body] [-a attachment]'
	argparser = OptionParser(usage = usage, description = 'Send email from a cluser node')
	argparser.add_option('-f', '--from', '--sender', dest='sender',
	help="email sender (From:)")
	argparser.add_option('-t', '--to', '--recipients', dest='recipients',
	action = 'append', help="email recipient (To:)")
	argparser.add_option('-s', '--subject', dest='subject',
	help="email subject (Subject:)")
	argparser.add_option('-b', '--body', dest='body',
	help="email body (default stdin)")
	argparser.add_option('-a', '--attachment', '--file', dest='attfiles',
	action = 'append', help="attachment filename")
	(options, args) = argparser.parse_args()
	if options.sender is None:
		fqdn = socket.getfqdn()
		sender = "root@%s" % fqdn
	else:
		sender = options.sender
	if options.recipients is None:
		argparser.error("Unable to send mail without at least one recipient");
		sys.exit(1);
	else:
		recipients = options.recipients
	if options.subject is None:
		subject = 'No subject specified'
	else:
		subject = options.subject
	if options.body is None:
		lines = sys.stdin.readlines()
		body = ''.join(lines)
	else:
		body = options.body
	if options.attfiles is None:
		atts = None
	else:
		atts = []
		for attfile in options.attfiles:
			att = EmailAttachmentFromFile(attfile)
			atts.append(att)
	try:
		Emailer.send_email(recipients, body, sender, subject, attachments = atts)
	except:
		print('Error sending email.')
		sys.exit(1)

	sys.exit(0)

if __name__ == "__main__":
	main()