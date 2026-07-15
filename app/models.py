from django.db import models

class Visit(models.Model):
    timestamp = models.DateTimeField(auto_now_add=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)

    def __str__(self):
        return f"Visit at {self.timestamp} from {self.ip_address or 'Unknown'}"
