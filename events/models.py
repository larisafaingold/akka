from django.db import models


class EventModel(models.Model):
    date = models.DateField()
    description = models.CharField(max_length=100)

    class Meta:
        app_label = 'events'