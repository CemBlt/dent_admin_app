/**
 * Doctor Management JavaScript
 * Accordion yönetimi ve doktor kartları işlevselliği
 */

// Accordion - Sadece tıklanan doktorun açılması ve default kapalı
(function() {
    'use strict';
    
    document.querySelectorAll('.doctor-accordion details').forEach(detail => {
        // İlk yüklemede tüm accordion'ları kapalı yap
        detail.open = false;
        
        detail.addEventListener('toggle', function() {
            if (this.open) {
                // Aynı doktor kartındaki diğer accordion'ları kapat
                const card = this.closest('.doctor-card');
                const otherDetails = card.querySelectorAll('.doctor-accordion details');
                otherDetails.forEach(other => {
                    if (other !== this && other.open) {
                        other.open = false;
                    }
                });
            }
        });
    });
})();

