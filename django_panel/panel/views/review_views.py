from datetime import datetime
from django.shortcuts import render, redirect
from django.views import View
from django.utils.decorators import method_decorator
from django.contrib import messages
from .auth_views import login_required
from ..forms import ReviewReplyForm, ReviewFilterForm
from ..utils import build_doctor_choices
from ..services import doctor_service, review_service, event_service

class ReviewManagementView(View):
    template_name = "panel/review_management.html"
    
    @method_decorator(login_required)
    def dispatch(self, request, *args, **kwargs):
        return super().dispatch(request, *args, **kwargs)

    def get(self, request):
        context = self._build_context(request)
        return render(request, self.template_name, context)

    def post(self, request):
        action = request.POST.get("form_type")

        if action == "add_reply":
            form = ReviewReplyForm(request.POST)
            if form.is_valid():
                review_id = form.cleaned_data["review_id"]
                reply_text = form.cleaned_data["reply"]
                review_service.add_reply(review_id, reply_text)
                messages.success(request, "Yanıt eklendi.")
                event_service.log_event(
                    "review_reply_added",
                    request=request,
                    properties={"review_id": review_id},
                )
                return redirect("review_management")

        elif action == "edit_reply":
            form = ReviewReplyForm(request.POST)
            if form.is_valid():
                review_id = form.cleaned_data["review_id"]
                reply_text = form.cleaned_data["reply"]
                review_service.add_reply(review_id, reply_text)
                messages.success(request, "Yanıt güncellendi.")
                event_service.log_event(
                    "review_reply_updated",
                    request=request,
                    properties={"review_id": review_id},
                )
                return redirect("review_management")

        elif action == "delete_reply":
            review_id = request.POST.get("review_id")
            if review_id:
                review_service.delete_reply(review_id)
                messages.success(request, "Yanıt silindi.")
                event_service.log_event(
                    "review_reply_deleted",
                    request=request,
                    properties={"review_id": review_id},
                )
                return redirect("review_management")

        context = self._build_context(request)
        return render(request, self.template_name, context)

    def _build_context(self, request):
        doctors = doctor_service.get_doctors(request)
        doctor_choices = build_doctor_choices(doctors)

        filter_form = ReviewFilterForm(
            request.GET,
            doctor_choices=doctor_choices,
        )

        doctor_id = request.GET.get("doctor") or None
        min_rating = int(request.GET.get("min_rating")) if request.GET.get("min_rating") else None
        max_rating = int(request.GET.get("max_rating")) if request.GET.get("max_rating") else None
        date_from = request.GET.get("date_from") or None
        date_to = request.GET.get("date_to") or None
        has_reply_str = request.GET.get("has_reply")
        has_reply = None
        if has_reply_str == "true":
            has_reply = True
        elif has_reply_str == "false":
            has_reply = False

        reviews = review_service.get_reviews_with_details(
            doctor_id=doctor_id,
            min_rating=min_rating,
            max_rating=max_rating,
            date_from=date_from,
            date_to=date_to,
            has_reply=has_reply,
            request=request,
        )

        stats = review_service.get_review_statistics(request=request)

        review_cards = []
        for review in reviews:
            created_at = review.get("createdAt", "")
            if created_at:
                try:
                    dt_str = created_at.replace("Z", "+00:00")
                    review["created_at_dt"] = datetime.fromisoformat(dt_str)
                except (ValueError, AttributeError):
                    review["created_at_dt"] = None
            else:
                review["created_at_dt"] = None
            
            replied_at = review.get("repliedAt", "")
            if replied_at:
                try:
                    dt_str = replied_at.replace("Z", "+00:00")
                    review["replied_at_dt"] = datetime.fromisoformat(dt_str)
                except (ValueError, AttributeError):
                    review["replied_at_dt"] = None
            else:
                review["replied_at_dt"] = None
            
            reply_form = ReviewReplyForm(initial={
                "review_id": review["id"],
                "reply": review.get("reply", ""),
            })
            review_cards.append({
                "data": review,
                "reply_form": reply_form,
            })

        context = {
            "page_title": "Yorumlar & Yanıtlar",
            "filter_form": filter_form,
            "review_cards": review_cards,
            "statistics": stats,
            "doctor_choices": doctor_choices,
        }
        return context

