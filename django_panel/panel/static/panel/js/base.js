/**
 * Base JavaScript Functions
 * Ortak kullanılan JavaScript fonksiyonları
 */

/**
 * Form onay dialogu gösterir
 * @param {string} message - Gösterilecek mesaj
 * @returns {boolean} - Kullanıcı onayladıysa true
 */
function confirmAction(message) {
    return confirm(message || 'Bu işlemi yapmak istediğinize emin misiniz?');
}

/**
 * Sayfa yüklendiğinde çalışacak fonksiyonları kaydeder
 */
document.addEventListener('DOMContentLoaded', function() {
    // Tüm onsubmit="return confirm(...)" formlarını otomatik işle
    const forms = document.querySelectorAll('form[onsubmit*="confirm"]');
    forms.forEach(form => {
        const onsubmitAttr = form.getAttribute('onsubmit');
        if (onsubmitAttr && onsubmitAttr.includes('confirm')) {
            // Mevcut onsubmit'i koru, sadece işaretle
            form.dataset.hasConfirm = 'true';
        }
    });
});

