from django.urls import path

from . import views

urlpatterns = [
    path('', views.dashboard, name='dashboard'),
    path('hospital/', views.HospitalSettingsView.as_view(), name='hospital_settings'),
    path('doctors/', views.DoctorManagementView.as_view(), name='doctor_management'),
    path('appointments/', views.AppointmentManagementView.as_view(), name='appointment_management'),
    path('schedule/', views.ScheduleManagementView.as_view(), name='schedule_management'),
    path('services/', views.ServiceManagementView.as_view(), name='service_management'),
    path('reviews/', views.ReviewManagementView.as_view(), name='review_management'),
    path('settings/', views.SettingsView.as_view(), name='settings'),
    path('api/locations/provinces/', views.location_provinces, name='location_provinces'),
    path('api/locations/districts/<str:province_id>/', views.location_districts, name='location_districts'),
    path('api/locations/neighborhoods/<str:district_id>/', views.location_neighborhoods, name='location_neighborhoods'),
]
