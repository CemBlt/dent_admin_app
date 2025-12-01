"""
Django management command to automatically update appointment statuses.

This command checks all appointments with 'planned' status and updates them
to 'completed' if their appointment time has passed.

Usage:
    python manage.py update_appointment_statuses

This command should be run periodically via cron (e.g., every hour).
"""

from django.core.management.base import BaseCommand
from datetime import datetime, timedelta
from panel.services.supabase_client import get_supabase_client


class Command(BaseCommand):
    help = 'Updates appointment statuses from planned to completed if appointment time has passed'

    def handle(self, *args, **options):
        supabase = get_supabase_client()
        now = datetime.now()
        
        # Get all appointments with 'planned' status
        result = supabase.table("appointments").select("*").eq("status", "planned").execute()
        
        if not result.data:
            self.stdout.write(self.style.SUCCESS('No planned appointments found.'))
            return
        
        updated_count = 0
        
        for appointment in result.data:
            try:
                # Parse appointment date and time
                date_str = appointment.get("date", "")
                time_str = appointment.get("time", "")
                
                if not date_str or not time_str:
                    continue
                
                # Combine date and time
                # Parse date (YYYY-MM-DD) and time (HH:MM or HH:MM:SS)
                date_obj = datetime.strptime(date_str, "%Y-%m-%d").date()
                
                # Parse time (HH:MM or HH:MM:SS)
                if len(time_str) == 5:  # HH:mm format
                    time_obj = datetime.strptime(time_str, "%H:%M").time()
                else:  # HH:mm:ss format
                    time_obj = datetime.strptime(time_str, "%H:%M:%S").time()
                
                # Combine date and time
                appointment_datetime = datetime.combine(date_obj, time_obj)
                
                # If appointment time has passed, update status to completed
                if appointment_datetime < now:
                    appointment_id = appointment.get("id")
                    supabase.table("appointments").update({"status": "completed"}).eq("id", appointment_id).execute()
                    updated_count += 1
                    self.stdout.write(
                        self.style.SUCCESS(
                            f'Updated appointment {appointment_id} from planned to completed'
                        )
                    )
            except (ValueError, TypeError) as e:
                self.stdout.write(
                    self.style.WARNING(
                        f'Error processing appointment {appointment.get("id", "unknown")}: {e}'
                    )
                )
                continue
        
        self.stdout.write(
            self.style.SUCCESS(
                f'Successfully updated {updated_count} appointment(s) from planned to completed.'
            )
        )

