from django.test import TestCase
from django.urls import reverse
from .models import Visit

class DevOpsPracticeTests(TestCase):
    def test_health_check_endpoint(self):
        """Verify the health-check endpoint works and returns a JSON response."""
        response = self.client.get(reverse('health'))
        # pyrefly: ignore [missing-attribute]
        self.assertEqual(response.status_code, 200)
        # pyrefly: ignore [missing-attribute]
        self.assertEqual(response.json()['status'], 'healthy')
        # pyrefly: ignore [missing-attribute]
        self.assertEqual(response.json()['database'], 'connected')

    def test_home_page_loads(self):
        """Verify the home page loads correctly and records a visit."""
        # pyrefly: ignore [missing-attribute]
        initial_visits = Visit.objects.count()
        response = self.client.get(reverse('home'))
        # pyrefly: ignore [missing-attribute]
        self.assertEqual(response.status_code, 200)
        
        # Verify that a visit was recorded
        # pyrefly: ignore [missing-attribute]
        self.assertEqual(Visit.objects.count(), initial_visits + 1)
        
        # Check some templates/context tags are in the response
        self.assertContains(response, 'DevOps Practice')
        self.assertContains(response, 'Total Visits')

    def test_home_page_renders_deploy_version(self):
        """Verify the home page loads and displays release version information."""
        # pyrefly: ignore [missing-attribute]
        response = self.client.get(reverse('home'))
        # pyrefly: ignore [missing-attribute]
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Release Version')
        self.assertContains(response, 'Local Dev')
