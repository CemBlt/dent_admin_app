from django.urls import path

from . import views

urlpatterns = [
    path('', views.dashboard, name='dashboard'),
    path('hospital/', views.HospitalSettingsView.as_view(), name='hospital_settings'),
    path('doctors/', views.DoctorManagementView.as_view(), name='doctor_management'),
]
