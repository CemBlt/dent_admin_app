"""
Base view classes for panel app.
Ortak view işlevselliği için base class'lar.
"""

from django.contrib import messages
from django.shortcuts import redirect, render
from django.views import View

from ..mixins import BasePanelViewMixin, HospitalContextMixin


class BasePanelView(HospitalContextMixin, BasePanelViewMixin, View):
    """
    Panel view'leri için base class.
    Hospital context ve page_title otomatik olarak eklenir.
    """
    
    def get(self, request):
        """GET request handler."""
        context = self.get_context_data()
        context.update(self.build_context(request))
        return render(request, self.template_name, context)
    
    def build_context(self, request):
        """
        View-specific context'i build eder.
        Override edilmeli.
        """
        return {}
    
    def get_page_title(self):
        """Sayfa başlığını döndürür. Override edilebilir."""
        return getattr(self, 'page_title', 'Panel')

