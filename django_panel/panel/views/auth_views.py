from functools import wraps
from django.shortcuts import render, redirect
from django.contrib import messages
from ..forms import LoginForm, HospitalRegistrationForm
from ..services import auth_service, hospital_registration_service, location_service
from ..services.supabase_client import get_supabase_client

# Login required decorator
def login_required(view_func):
    """Kullanıcının giriş yapmış olmasını kontrol eder."""
    @wraps(view_func)
    def _wrapped_view(request, *args, **kwargs):
        if not request.session.get('user_id') or not request.session.get('hospital_id'):
            messages.warning(request, "Lütfen giriş yapın.")
            return redirect('login')
        return view_func(request, *args, **kwargs)
    return _wrapped_view

def login_view(request):
    """Kullanıcı giriş sayfası."""
    if request.method == 'POST':
        form = LoginForm(request.POST)
        if form.is_valid():
            hospital_code = form.cleaned_data['hospital_code']
            email = form.cleaned_data['email']
            password = form.cleaned_data['password']
            
            try:
                # 1. Hospital code'dan hospital_id bul
                supabase = get_supabase_client()
                hospital_result = supabase.table("hospitals").select("id, status, name").eq("hospital_code", hospital_code).single().execute()
                
                if not hospital_result.data:
                    messages.error(request, "Geçersiz hastane kodu.")
                    return render(request, "panel/login.html", {"form": form})
                
                hospital = hospital_result.data
                
                # 2. Hastane onaylanmış mı kontrol et
                if hospital.get("status") != "approved":
                    messages.error(request, "Hastaneniz henüz onaylanmamış. Lütfen onay bekleyin.")
                    return render(request, "panel/login.html", {"form": form})
                
                # 3. Supabase Auth ile giriş yap
                auth_response = auth_service.sign_in(email, password)
                user_id = auth_response["user_id"]
                
                # 4. Kullanıcının bu hastaneye ait olduğunu kontrol et
                hospital_check = supabase.table("hospitals").select("id").eq("id", hospital["id"]).eq("created_by_user_id", user_id).execute()
                
                if not hospital_check.data:
                    messages.error(request, "Bu email adresi bu hastaneye ait değil.")
                    return render(request, "panel/login.html", {"form": form})
                
                # 5. Session'a kaydet
                request.session['user_id'] = user_id
                request.session['hospital_id'] = str(hospital["id"])
                request.session['hospital_name'] = hospital.get("name", "")
                request.session['user_email'] = email
                
                messages.success(request, f"Hoş geldiniz, {hospital.get('name', '')}!")
                return redirect('dashboard')
                
            except ValueError as e:
                messages.error(request, str(e))
            except Exception as e:
                messages.error(request, f"Giriş yapılamadı: {str(e)}")
    else:
        form = LoginForm()
    
    return render(request, "panel/login.html", {"form": form})

def register_view(request):
    """Hastane kayıt sayfası."""
    if request.method == 'POST':
        # Lokasyon seçeneklerini hazırla
        province_choices = location_service.as_choice_tuples(location_service.get_provinces())
        province_id = request.POST.get("province")
        district_choices = []
        neighborhood_choices = []
        
        if province_id:
            district_choices = location_service.as_choice_tuples(location_service.get_districts(province_id))
            district_id = request.POST.get("district")
            if district_id:
                neighborhood_choices = location_service.as_choice_tuples(location_service.get_neighborhoods(district_id))
        
        form = HospitalRegistrationForm(
            request.POST,
            request.FILES,
            province_choices=province_choices,
            district_choices=district_choices,
            neighborhood_choices=neighborhood_choices,
        )
        
        if form.is_valid():
            try:
                result = hospital_registration_service.register_hospital(form.cleaned_data, request.FILES.get("logo"))
                messages.success(
                    request,
                    "Kayıt başarıyla oluşturuldu! "
                    "Kaydınız admin tarafından onaylandıktan sonra giriş yapabileceksiniz. "
                    "Onay sonrası email adresinize giriş kodunuz gönderilecektir."
                )
                return redirect('login')
            except ValueError as e:
                messages.error(request, str(e))
            except Exception as e:
                messages.error(request, f"Kayıt oluşturulamadı: {str(e)}")
    else:
        province_choices = location_service.as_choice_tuples(location_service.get_provinces())
        form = HospitalRegistrationForm(
            province_choices=province_choices,
            district_choices=[],
            neighborhood_choices=[],
        )
    
    return render(request, "panel/register.html", {"form": form})

def logout_view(request):
    """Kullanıcı çıkışı."""
    request.session.flush()
    messages.success(request, "Başarıyla çıkış yaptınız.")
    return redirect('login')

