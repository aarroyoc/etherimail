import subprocess
import time
import smtplib
from email.message import EmailMessage
from unittest import TestCase

class Smtp(TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = subprocess.Popen(["/home/aarroyoc/dev/scryer-prolog/target/release/scryer-prolog", "../smtp-server/smtp.pl"])
        time.sleep(10)
    
    @classmethod
    def tearDownClass(cls):
        cls.server.terminate()

    def test_send_mail(self):
        server = smtplib.SMTP('localhost', 2500)
        server.set_debuglevel(1)
        server.sendmail("adrian@origin.com", "mario@dest.com", "Test")
        server.quit()

    def test_send_message(self):
        server = smtplib.SMTP('localhost', 2500)
        server.set_debuglevel(1)
        msg = EmailMessage()
        msg.set_content("Welcome to EtheriMail")
        msg["Subject"] = "A subject"
        msg["From"] = "adrian@python.com"
        msg["To"] = "de288305-2103-497b-9f33-b1e5bd976eb1@etherimail.com"
        server.send_message(msg)
        server.quit()