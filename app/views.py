import os
import socket
import sys
import platform
from django.shortcuts import render
from django.http import JsonResponse
from django.conf import settings
from django.db import connection
from django.utils import timezone
from .models import Visit

def get_client_ip(request):
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        ip = x_forwarded_for.split(',')[0]
    else:
        ip = request.META.get('REMOTE_ADDR')
    return ip

def home_view(request):
    client_ip = get_client_ip(request)
    
    # Try to record visit in DB (handles cases where DB migrations haven't run yet)
    db_status = "Connected"
    visit_count = 0
    recent_visits = []
    try:
        # Create a new visit entry
        Visit.objects.create(ip_address=client_ip)
        visit_count = Visit.objects.count()
        recent_visits = Visit.objects.order_by('-timestamp')[:5]
    except Exception as e:
        db_status = f"Unavailable ({str(e)})"
    
    # Gather system info
    try:
        hostname = socket.gethostname()
        host_ip = socket.gethostbyname(hostname)
    except Exception:
        hostname = "unknown"
        host_ip = "unknown"

    db_engine = settings.DATABASES['default']['ENGINE'].split('.')[-1]
    deploy_version = os.environ.get('DEPLOY_VERSION') or os.environ.get('GIT_SHA') or 'Local Dev'
    
    import django
    context = {
        'hostname': hostname,
        'host_ip': host_ip,
        'os_info': platform.platform(),
        'python_version': sys.version,
        'django_version': django.get_version(),
        'db_status': db_status,
        'db_engine': db_engine,
        'visit_count': visit_count,
        'recent_visits': recent_visits,
        'current_time': timezone.now(),
        'debug_mode': settings.DEBUG,
        'deploy_version': deploy_version,
    }
    
    return render(request, 'app/index.html', context)

def health_view(request):
    health = {
        "status": "healthy",
        "timestamp": timezone.now().isoformat(),
        "database": "unknown"
    }
    
    try:
        # Check database connection
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1;")
            row = cursor.fetchone()
        if row and row[0] == 1:
            health["database"] = "connected"
        else:
            health["database"] = "unhealthy"
            health["status"] = "unhealthy"
    except Exception as e:
        health["database"] = f"error: {str(e)}"
        health["status"] = "unhealthy"
        
    status_code = 200 if health["status"] == "healthy" else 500
    return JsonResponse(health, status=status_code)
