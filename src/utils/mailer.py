import smtplib
import os
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from src.config import settings
from src.utils.logger import logger

def send_emails(recipients, subject, body, attachments=None):
    """
    Sends an email to a list of recipients with optional attachments.
    """
    if not recipients:
        return

    if not settings.SENDER_EMAIL or not settings.SENDER_PASSWORD:
        logger.error("Email credentials not configured in .env")
        return

    try:
        msg = MIMEMultipart()
        msg['From'] = settings.SENDER_EMAIL
        msg['To'] = ", ".join(recipients)
        msg['Subject'] = subject

        msg.attach(MIMEText(body, 'plain'))

        if attachments:
            for filepath in attachments:
                if os.path.exists(filepath):
                    part = MIMEBase('application', "octet-stream")
                    with open(filepath, 'rb') as file:
                        part.set_payload(file.read())
                    encoders.encode_base64(part)
                    part.add_header('Content-Disposition', f'attachment; filename="{os.path.basename(filepath)}"')
                    msg.attach(part)

        server = smtplib.SMTP_SSL(settings.SMTP_SERVER, settings.SMTP_PORT)
        server.login(settings.SENDER_EMAIL, settings.SENDER_PASSWORD)
        server.send_message(msg)
        server.quit()
        logger.info(f"Email sent successfully to: {recipients}")
    except Exception as e:
        logger.error(f"Failed to send email: {e}")
