/**
 * Hospital Settings JavaScript
 * İl/İlçe/Mahalle yönetimi ve tatil form işlevselliği
 */

// İl / İlçe / Mahalle Yönetimi
(function() {
    'use strict';
    
    const form = document.getElementById('general-info-form');
    if (!form) return;

    const provinceSelect = document.getElementById('id_province');
    const districtSelect = document.getElementById('id_district');
    const neighborhoodSelect = document.getElementById('id_neighborhood');

    if (!provinceSelect || !districtSelect || !neighborhoodSelect) return;

    const endpoints = {
        provinces: form.dataset.provincesUrl,
        districts: form.dataset.districtsUrl || '',
        neighborhoods: form.dataset.neighborhoodsUrl || '',
    };

    const initialState = {
        province: provinceSelect.dataset.initial || '',
        district: districtSelect.dataset.initial || '',
        neighborhood: neighborhoodSelect.dataset.initial || '',
    };

    const disableSelect = (select, placeholder) => {
        if (!select) return;
        select.innerHTML = `<option value="">${placeholder}</option>`;
        select.value = '';
        select.setAttribute('disabled', 'disabled');
    };

    const populateSelect = (select, items, placeholder) => {
        select.removeAttribute('disabled');
        const options = [`<option value="">${placeholder}</option>`];
        items.forEach(item => {
            options.push(`<option value="${item.id}">${item.name}</option>`);
        });
        select.innerHTML = options.join('');
    };

    const fetchJSON = async (url) => {
        const response = await fetch(url);
        if (!response.ok) {
            throw new Error('Veri alınamadı');
        }
        const payload = await response.json();
        return payload.results || [];
    };

    const buildUrl = (template, value) => template.replace('__PROVINCE__', value).replace('__DISTRICT__', value);

    const loadNeighborhoods = async (districtId, preserveInitial = false) => {
        if (!districtId) {
            disableSelect(neighborhoodSelect, 'Önce ilçe seçin');
            return;
        }
        try {
            const url = buildUrl(endpoints.neighborhoods, districtId);
            const neighborhoods = await fetchJSON(url);
            populateSelect(neighborhoodSelect, neighborhoods, 'Mahalle seçin');
            if (preserveInitial && initialState.neighborhood) {
                neighborhoodSelect.value = initialState.neighborhood;
                initialState.neighborhood = '';
            }
        } catch (error) {
            console.error('Mahalle listesi yüklenemedi', error);
            disableSelect(neighborhoodSelect, 'Mahalle yüklenemedi');
        }
    };

    const loadDistricts = async (provinceId, preserveInitial = false) => {
        if (!provinceId) {
            disableSelect(districtSelect, 'Önce il seçin');
            disableSelect(neighborhoodSelect, 'Önce ilçe seçin');
            return;
        }
        try {
            const url = buildUrl(endpoints.districts, provinceId);
            const districts = await fetchJSON(url);
            populateSelect(districtSelect, districts, 'İlçe seçin');
            if (preserveInitial && initialState.district) {
                districtSelect.value = initialState.district;
                const nextDistrict = initialState.district;
                initialState.district = '';
                await loadNeighborhoods(nextDistrict, true);
            } else {
                disableSelect(neighborhoodSelect, 'Önce ilçe seçin');
            }
        } catch (error) {
            console.error('İlçe listesi yüklenemedi', error);
            disableSelect(districtSelect, 'İlçe yüklenemedi');
            disableSelect(neighborhoodSelect, 'Önce ilçe seçin');
        }
    };

    const loadProvinces = async () => {
        try {
            const provinces = await fetchJSON(endpoints.provinces);
            populateSelect(provinceSelect, provinces, 'İl seçin');
            if (initialState.province) {
                provinceSelect.value = initialState.province;
                const nextProvince = initialState.province;
                initialState.province = '';
                await loadDistricts(nextProvince, true);
            } else {
                disableSelect(districtSelect, 'Önce il seçin');
                disableSelect(neighborhoodSelect, 'Önce ilçe seçin');
            }
        } catch (error) {
            console.error('İl listesi yüklenemedi', error);
            disableSelect(provinceSelect, 'İl yüklenemedi');
            disableSelect(districtSelect, 'Önce il seçin');
            disableSelect(neighborhoodSelect, 'Önce ilçe seçin');
        }
    };

    provinceSelect.addEventListener('change', (event) => {
        const provinceId = event.target.value;
        loadDistricts(provinceId);
    });

    districtSelect.addEventListener('change', (event) => {
        const districtId = event.target.value;
        loadNeighborhoods(districtId);
    });

    loadProvinces();
})();

// Tab Yönetimi
(function() {
    'use strict';
    
    const tabInputs = document.querySelectorAll('.tab-container input[type="radio"]');
    const tabPanels = document.querySelectorAll('.tab-panel');
    
    function showTab(tabId) {
        // Tüm panel'leri gizle
        tabPanels.forEach(panel => {
            panel.style.display = 'none';
        });
        
        // Seçilen tab'ın panel'ini göster
        const panelId = 'panel-' + tabId.replace('tab-', '');
        const panel = document.getElementById(panelId);
        if (panel) {
            panel.style.display = 'block';
        }
        
        // URL hash'ini güncelle (opsiyonel, daha iyi UX için)
        const hash = tabId.replace('tab-', '');
        if (history.pushState) {
            history.pushState(null, null, '#' + hash);
        } else {
            window.location.hash = hash;
        }
    }
    
    // Sayfa yüklendiğinde checked olan tab'ı göster
    function initTabs() {
        const checkedTab = document.querySelector('.tab-container input[type="radio"]:checked');
        if (checkedTab) {
            showTab(checkedTab.id);
        } else {
            // Eğer hiç checked yoksa, URL hash'ine bak
            const hash = window.location.hash.replace('#', '');
            if (hash) {
                const tabInput = document.getElementById('tab-' + hash);
                if (tabInput) {
                    tabInput.checked = true;
                    showTab(tabInput.id);
                    return;
                }
            }
            // Varsayılan olarak genel bilgiler
            showTab('tab-general');
        }
    }
    
    // Sayfa yüklendiğinde çalıştır
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initTabs);
    } else {
        initTabs();
    }
    
    // Tab değişikliklerini dinle
    tabInputs.forEach(input => {
        input.addEventListener('change', function() {
            if (this.checked) {
                showTab(this.id);
            }
        });
    });
    
    // Browser back/forward butonları için hash değişikliklerini dinle
    window.addEventListener('hashchange', function() {
        const hash = window.location.hash.replace('#', '');
        if (hash) {
            const tabInput = document.getElementById('tab-' + hash);
            if (tabInput) {
                tabInput.checked = true;
                showTab(tabInput.id);
            }
        }
    });
})();

// Tatil Form - Tüm Gün Checkbox Kontrolü ve Tarih Seçimi
(function() {
    'use strict';
    
    const fullDayCheckbox = document.querySelector('#holiday-form input[type="checkbox"][name="is_full_day"]');
    const timeFields = document.querySelectorAll('#holiday-form .time-fields');
    const dateInput = document.querySelector('#holiday-form input[type="date"][name="date"]');
    const endTimeSelect = document.querySelector('#holiday-form select[name="end_time"]');
    
    // Hastane çalışma saatlerini JavaScript'e aktar
    const workingHoursElement = document.getElementById('working-hours-data');
    if (!workingHoursElement) return;
    
    let workingHours = {};
    try {
        workingHours = JSON.parse(workingHoursElement.textContent);
    } catch (e) {
        console.error('Çalışma saatleri verisi parse edilemedi', e);
        return;
    }
    
    // Haftanın günü isimlerini sayıya çevir (0=Pazartesi, 6=Pazar)
    const weekdayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    
    function getWeekdayName(dateString) {
        if (!dateString) return null;
        const date = new Date(dateString + 'T00:00:00');
        const weekday = date.getDay(); // 0=Pazar, 1=Pazartesi, ..., 6=Cumartesi
        // JavaScript'in getDay() 0=Pazar döndürür, bizim sistemimiz 0=Pazartesi
        // Bu yüzden dönüşüm yapıyoruz
        const adjustedWeekday = weekday === 0 ? 6 : weekday - 1; // 0=Pazartesi, 6=Pazar
        return weekdayNames[adjustedWeekday];
    }
    
    function setEndTimeFromWorkingHours() {
        if (!dateInput || !endTimeSelect || fullDayCheckbox.checked) return;
        
        const dateValue = dateInput.value;
        if (!dateValue) return;
        
        const weekdayName = getWeekdayName(dateValue);
        if (!weekdayName) return;
        
        const dayHours = workingHours[weekdayName];
        if (dayHours && dayHours.isAvailable && dayHours.end) {
            // Mesai bitiş saatini bitiş saati dropdown'ına ayarla
            endTimeSelect.value = dayHours.end;
        }
    }
    
    function toggleTimeFields() {
        if (fullDayCheckbox.checked) {
            timeFields.forEach(field => {
                field.style.display = 'none';
                const select = field.querySelector('select');
                if (select) {
                    select.value = '';
                    select.required = false;
                }
            });
        } else {
            timeFields.forEach(field => {
                field.style.display = 'block';
                const select = field.querySelector('select');
                if (select) {
                    select.required = true;
                }
            });
            // Tarih seçiliyse bitiş saatini ayarla
            setEndTimeFromWorkingHours();
        }
    }
    
    if (fullDayCheckbox) {
        fullDayCheckbox.addEventListener('change', toggleTimeFields);
        toggleTimeFields(); // İlk yüklemede kontrol et
    }
    
    if (dateInput) {
        dateInput.addEventListener('change', setEndTimeFromWorkingHours);
    }
})();

// 7/24 Açık Checkbox Kontrolü - Çalışma Saatleri
(function() {
    'use strict';
    
    const isOpen24HoursCheckbox = document.getElementById('id_is_open_24_hours');
    const hoursTable = document.getElementById('hours-table');
    
    if (!isOpen24HoursCheckbox || !hoursTable) return;
    
    function toggleWorkingHoursFields() {
        const isChecked = isOpen24HoursCheckbox.checked;
        const rows = hoursTable.querySelectorAll('tbody tr');
        
        rows.forEach(row => {
            // Açık checkbox'ı bul
            const openCheckbox = row.querySelector('input[type="checkbox"]');
            // Başlangıç ve bitiş select'lerini bul
            const startSelect = row.querySelector('select[name$="_start"]');
            const endSelect = row.querySelector('select[name$="_end"]');
            
            if (isChecked) {
                // 7/24 açıksa tüm günleri açık yap ve saat alanlarını devre dışı bırak
                if (openCheckbox) {
                    openCheckbox.checked = true;
                    openCheckbox.disabled = true;
                }
                if (startSelect) {
                    startSelect.value = '';
                    startSelect.disabled = true;
                }
                if (endSelect) {
                    endSelect.value = '';
                    endSelect.disabled = true;
                }
            } else {
                // 7/24 açık değilse alanları aktif et
                if (openCheckbox) {
                    openCheckbox.disabled = false;
                }
                if (startSelect) {
                    startSelect.disabled = false;
                }
                if (endSelect) {
                    endSelect.disabled = false;
                }
            }
        });
    }
    
    // İlk yüklemede kontrol et
    toggleWorkingHoursFields();
    
    // Checkbox değişikliklerini dinle
    isOpen24HoursCheckbox.addEventListener('change', toggleWorkingHoursFields);
})();

