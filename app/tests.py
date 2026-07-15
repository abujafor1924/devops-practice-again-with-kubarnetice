from django.test import TestCase
from django.urls import reverse
from .models import Visit

class DevOpsPracticeTests(TestCase):
    def test_health_check_endpoint(self):
        """Verify the health-check endpoint works and returns a JSON response."""
        response = self.client.get(reverse('health'))
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()['status'], 'healthy')
        self.assertEqual(response.json()['database'], 'connected')

    def test_home_page_loads(self):
        """Verify the home page loads correctly and records a visit."""
        initial_visits = Visit.objects.count()
        response = self.client.get(reverse('home'))
        self.assertEqual(response.status_code, 200)
        
        # Verify that a visit was recorded
        self.assertEqual(Visit.objects.count(), initial_visits + 1)
        
        # Check some templates/context tags are in the response
        self.assertContains(response, 'DevOps Practice')
        self.assertContains(response, 'Total Visits')
