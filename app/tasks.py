import time

# pyrefly: ignore [missing-import]
from celery import shared_task


@shared_task
def add(x, y):
    return x + y

@shared_task
def long_task():
    time.sleep(60)
    return "Task Completed"

@shared_task
def send_email(email):
    try:
        print(f"Sending email to {email}")
        time.sleep(10)
        print(f"Email sent to {email}")
        return "Email Sent"
    except Exception as e:
        print(e)
        return "Email Not Sent"
    
