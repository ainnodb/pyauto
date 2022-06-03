#!/opt/bosap/toolset/bin/python3 -E
"""
sum_monitor.py

Monitor SUM progress and send mail in case user interaction is required.
"""
import argparse
import re
import logging
from time import sleep
import os
from bosap import sendmail

logger = logging.getLogger(__file__)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(module)-12.12s] [%(levelname)-5.5s]  %(message)s",
    handlers=[logging.StreamHandler()]
)


def monitor(sid, recipients, phone_numbers, sms_sender_mail):
    logger.info("Send test mail...")

    if recipients and not sendmail.sendmail(recipients, subject=f"{sid}: SUM - Initial Test Mail"):
        logger.error("Sending of test mail failed..")
        exit(1)

    if phone_numbers and not sendmail.sendmail(phone_numbers, sender=sms_sender_mail, subject=f"{sid}: SUM - Initial Test SMS"):
        logger.error("Sending of test SMS failed..")
        exit(1)

    logger.info("Start monitoring of SUM")

    sum_dialog_file = f"/var/logs/SAPupDialog.txt"
    sum_alert_file = f"/var/logs//upalert.log"

    sum_dialog_file_timestamp = None
    sum_alert_file_timestamp = None

    while True:

        if os.path.exists(sum_dialog_file):
            sum_dialog_file_timestamp = check_file(sid, sum_dialog_file, sum_dialog_file_timestamp, recipients, phone_numbers, sms_sender_mail)
        elif os.path.exists(sum_alert_file):
            sum_alert_file_timestamp = check_file(sid, sum_alert_file, sum_alert_file_timestamp, recipients,phone_numbers, sms_sender_mail)
        else:
            logger.debug('Neither dialog nor alert file exists --> reset timestamps')
            sum_alert_file_timestamp = None
            sum_dialog_file_timestamp = None

        # wait 1 min
        sleep(60)


def check_file(sid, file, last_timestamp, recipients, phone_numbers, sms_sender_mail):
    sum_phase_file = f"/global.{sid}/upgrade/SUM/abap/log/SAPupStat.log"

    logger.debug(f"File {file} exists --> check timestamp")
    file_timestamp = os.path.getmtime(file)
    logger.debug(f"file timestamp: {file_timestamp}")
    logger.debug(f"last timestamp: {last_timestamp}")
    if file_timestamp != last_timestamp:
        # get content of file
        content = read_file(file)
        # get subject
        m = re.search(r'[=]{11} (.*) [=]{11}', content)
        if m:
            subject = f"{sid}: SUM - Step: {m.group(1)}"
        else:
            subject = f"{sid}: SUM - Action Required"


        # In case of alert file we should only send notification if Waiting for... is in content
        if file.endswith('upalert.log') and 'Waiting for input in phase' not in content:
            return last_timestamp

        logger.info(f"Send notification mail - Subject: {subject}")

        if recipients and sendmail.sendmail(recipients, subject=subject, message_text=content):
            # set timestamp var -- only if mail has been send successfully
            last_timestamp = file_timestamp

        if phone_numbers and sendmail.sendmail(phone_numbers, sender=sms_sender_mail, subject=subject):
            # set timestamp var -- only if mail has been send successfully
            last_timestamp = file_timestamp

    return last_timestamp


def read_file(path):
    """
    Return content of file
    :param path:
    :return:
    """
    with open(path, 'r', encoding='utf-8') as fp:
        content = fp.read()
    return content


if __name__ == '__main__':
    # Argparser
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('sid', help="SID of SAP System")
    parser.add_argument('recipients', help='List of mail recipients (separated by space, semicolon (;) or colon (,)', nargs='?')
    parser.add_argument('-n', '-p', '--phone_numbers',help='List of phone numbers that should recieve a mail (separated by space, semicolon (;) or colon (,)',default=None)
    parser.add_argument('-s', '--sms_sender_mail', default='motingxia@163.com',
                        help="Mail address that is used as an SMS sender (This mail address needs to be entitled to use SMS/FAX service provided by Bosch")
    parser.add_argument('-v', '--verbose',
                        help='Verbose output', action='store_true')
    args = parser.parse_args()

    # Convert recpients to list
    if args.recipients:
        recipients = re.split(r' |;|,', args.recipients)
    else:
        recipients = []

    if args.phone_numbers:
        phone_numbers = []
        for number in re.split(r' |;|,', args.phone_numbers):
            phone_numbers.append(f"sms={number}@rb-sms.emea.bosch.com")
    else:
        phone_numbers = None

    # Fail if no recipient/phone_number is defined
    if not recipients and not phone_numbers:
        print("No recipients or phone number specified. Abort!")
        exit(1)

    # verbose
    if args.verbose:
        logger.setLevel(logging.DEBUG)

    monitor(args.sid.upper(), recipients, phone_numbers, args.sms_sender_mail)




        