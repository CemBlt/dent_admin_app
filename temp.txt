from __future__ import annotations

from datetime import date, time as time_obj
from types import SimpleNamespace
from unittest import TestCase
from unittest.mock import MagicMock, call, patch

from panel.services import appointment_service


def _build_query(result_rows):
    """Creates a Supabase-style query mock that always returns result_rows."""
    query = MagicMock()
    for method in ("select", "eq", "gte", "lte", "is_", "update", "delete", "insert", "single", "limit"):
        setattr(query, method, MagicMock(return_value=query))
    query.execute.return_value = SimpleNamespace(data=result_rows)
    return query


class FilterAppointmentsTests(TestCase):
    @patch("panel.services.appointment_service._get_active_hospital_id", return_value="hospital-42")
    @patch("panel.services.appointment_service.get_supabase_client")
    def test_filter_appointments_applies_filters_and_formats_rows(self, mock_get_client, _):
        db_rows = [
            {
                "id": 7,
                "user_id": 3,
                "hospital_id": "hospital-42",
                "doctor_id": 11,
                "service_id": 5,
                "date": "2024-02-10",
                "time": "09:15",
                "status": "confirmed",
                "notes": "Kontrol",
                "created_at": "2024-02-01T10:00:00Z",
            }
        ]
        query = _build_query(db_rows)
        mock_supabase = MagicMock()
        mock_supabase.table.return_value = query
        mock_get_client.return_value = mock_supabase

        result = appointment_service.filter_appointments(
            status="confirmed",
            doctor_id="doctor-11",
            service_id="service-5",
            start_date=date(2024, 2, 1),
            end_date=date(2024, 2, 28),
            request=object(),
        )

        self.assertEqual(
            query.eq.call_args_list[:4],
            [
                call("hospital_id", "hospital-42"),
                call("status", "confirmed"),
                call("doctor_id", "doctor-11"),
                call("service_id", "service-5"),
            ],
        )
        query.gte.assert_called_once_with("date", "2024-02-01")
        query.lte.assert_called_once_with("date", "2024-02-28")
        self.assertEqual(
            result,
            [
                {
                    "id": "7",
                    "userId": "3",
                    "hospitalId": "hospital-42",
                    "doctorId": "11",
                    "date": "2024-02-10",
                    "time": "09:15",
                    "status": "confirmed",
                    "service": "5",
                    "notes": "Kontrol",
                    "createdAt": "2024-02-01T10:00:00Z",
                }
            ],
        )


class UpdateAppointmentTests(TestCase):
    @patch("panel.services.appointment_service.get_supabase_client")
    def test_update_appointment_converts_datetime_fields(self, mock_get_client):
        query = _build_query(
            [
                {
                    "id": "apt-1",
                    "user_id": "user-9",
                    "hospital_id": "hospital-1",
                    "doctor_id": "doc-2",
                    "date": "2024-03-05",
                    "time": "13:30",
                    "status": "cancelled",
                    "service_id": "svc-8",
                    "notes": "N/A",
                    "created_at": "2024-03-01T12:00:00Z",
                }
            ]
        )
        mock_supabase = MagicMock()
        mock_supabase.table.return_value = query
        mock_get_client.return_value = mock_supabase

        response = appointment_service.update_appointment(
            "apt-1",
            status="cancelled",
            date=date(2024, 3, 5),
            time=time_obj(hour=13, minute=30),
        )

        query.update.assert_called_once_with(
            {"status": "cancelled", "date": "2024-03-05", "time": "13:30"}
        )
        query.eq.assert_called_once_with("id", "apt-1")
        self.assertEqual(response["id"], "apt-1")
        self.assertEqual(response["status"], "cancelled")
        self.assertEqual(response["time"], "13:30")

    @patch("panel.services.appointment_service.get_supabase_client")
    def test_update_appointment_raises_when_supabase_returns_empty(self, mock_get_client):
        query = _build_query([])
        mock_supabase = MagicMock()
        mock_supabase.table.return_value = query
        mock_get_client.return_value = mock_supabase

        with self.assertRaises(ValueError):
            appointment_service.update_appointment("apt-404", status="completed")


class AppointmentBlockingTests(TestCase):
    @patch("panel.services.appointment_service._get_active_hospital_id", return_value="hospital-1")
    @patch("panel.services.appointment_service.get_supabase_client")
    def test_is_appointment_time_blocked_true_for_partial_holiday(self, mock_get_client, _):
        query = _build_query(
            [
                {
                    "is_full_day": False,
                    "start_time": "09:00",
                    "end_time": "11:00",
                }
            ]
        )
        mock_supabase = MagicMock()
        mock_supabase.table.return_value = query
        mock_get_client.return_value = mock_supabase

        is_blocked = appointment_service.is_appointment_time_blocked(
            appointment_date=date(2024, 4, 1),
            appointment_time="10:15",
            request=object(),
        )

        self.assertTrue(is_blocked)
        query.eq.assert_any_call("date", "2024-04-01")
        query.eq.assert_any_call("hospital_id", "hospital-1")

    @patch("panel.services.appointment_service._get_active_hospital_id", return_value="hospital-1")
    @patch("panel.services.appointment_service.get_supabase_client")
    def test_is_appointment_time_blocked_returns_false_for_outside_range(self, mock_get_client, _):
        query = _build_query(
            [
                {
                    "is_full_day": False,
                    "start_time": "09:00",
                    "end_time": "11:00",
                }
            ]
        )
        mock_supabase = MagicMock()
        mock_supabase.table.return_value = query
        mock_get_client.return_value = mock_supabase

        self.assertFalse(
            appointment_service.is_appointment_time_blocked(
                appointment_date=date(2024, 4, 1),
                appointment_time="13:00",
            )
        )


