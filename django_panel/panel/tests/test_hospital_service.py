from __future__ import annotations

from datetime import time as time_obj
from unittest import TestCase

from panel.forms import DAYS
from panel.services import hospital_service


class WorkingHoursBuilderTests(TestCase):
    def test_build_working_hours_from_form_for_24_hours(self):
        result = hospital_service.build_working_hours_from_form({"is_open_24_hours": True})

        for day_key, _ in DAYS:
            self.assertIn(day_key, result)
            self.assertEqual(
                result[day_key],
                {
                    "isAvailable": True,
                    "start": None,
                    "end": None,
                },
            )

    def test_build_working_hours_from_form_with_regular_hours(self):
        cleaned_data = {
            "is_open_24_hours": False,
            "monday_is_open": True,
            "monday_start": "08:30",
            "monday_end": "17:15",
            "tuesday_is_open": False,
            "tuesday_start": time_obj(hour=9, minute=0),
            "tuesday_end": time_obj(hour=12, minute=30),
        }

        result = hospital_service.build_working_hours_from_form(cleaned_data)

        self.assertEqual(
            result["monday"],
            {"isAvailable": True, "start": "08:30", "end": "17:15"},
        )
        self.assertEqual(
            result["tuesday"],
            {"isAvailable": False, "start": "09:00", "end": "12:30"},
        )


class WorkingHoursInitialTests(TestCase):
    def test_build_initial_working_hours_converts_strings_to_time_objects(self):
        hospital = {
            "is_open_24_hours": False,
            "workingHours": {
                "monday": {"isAvailable": True, "start": "08:00", "end": "17:00"},
                "tuesday": {"isAvailable": False, "start": None, "end": None},
            },
        }

        initial = hospital_service.build_initial_working_hours(hospital)

        self.assertTrue(initial["monday_is_open"])
        self.assertFalse(initial["tuesday_is_open"])
        self.assertEqual(str(initial["monday_start"]), "08:00:00")
        self.assertEqual(str(initial["monday_end"]), "17:00:00")
        self.assertIsNone(initial["tuesday_start"])
        self.assertIsNone(initial["tuesday_end"])


