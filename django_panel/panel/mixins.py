"""
View mixins for panel app.
Ortak view işlevselliği için mixin'ler.
"""

from django.contrib import messages
from django.shortcuts import redirect


class HospitalContextMixin:
    """
    Hospital bilgisini context'e ekler.
    Not: Context processor kullanıldığı için artık gerekli değil,
    ama geriye dönük uyumluluk için tutuluyor.
    """
    
    def get_context_data(self, **kwargs):
        """Context'e hospital bilgisini ekler."""
        context = super().get_context_data(**kwargs) if hasattr(super(), 'get_context_data') else {}
        # Context processor zaten ekliyor, ama override edilmişse tekrar ekleme
        if 'hospital' not in context:
            from .services import hospital_service
            context['hospital'] = hospital_service.get_hospital()
        return context


class BasePanelViewMixin:
    """
    Panel view'leri için base mixin.
    Ortak metodlar ve işlevsellik sağlar.
    """
    
    def get_page_title(self):
        """Sayfa başlığını döndürür. Override edilebilir."""
        return getattr(self, 'page_title', 'Panel')
    
    def get_context_data(self, **kwargs):
        """Context'e page_title ekler."""
        context = super().get_context_data(**kwargs) if hasattr(super(), 'get_context_data') else {}
        context['page_title'] = self.get_page_title()
        return context


class FormActionMixin:
    """
    Form action'larını yönetmek için mixin.
    POST request'lerinde form_type'a göre işlem yapar.
    """
    
    def handle_form_action(self, request, action):
        """
        Form action'ını handle eder.
        Override edilerek özel action'lar eklenebilir.
        """
        return None  # Override edilmeli
    
    def post(self, request):
        """POST request'ini handle eder."""
        action = request.POST.get("form_type")
        if action:
            result = self.handle_form_action(request, action)
            if result:
                return result
        
        # Default: context'i build et ve render et
        context = self.get_context_data()
        return self.render_to_response(context) if hasattr(self, 'render_to_response') else self.render(request, context)
    
    def render(self, request, context):
        """Render helper method."""
        from django.shortcuts import render
        return render(request, self.template_name, context)

