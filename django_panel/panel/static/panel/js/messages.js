/**
 * Mesaj Yönetimi
 * Django messages framework'ünden gelen mesajların otomatik kapanmasını sağlar
 */
(function() {
    'use strict';
    
    const messages = document.querySelectorAll('.message');
    messages.forEach(message => {
        // 5 saniye sonra otomatik kapan
        setTimeout(() => {
            message.style.opacity = '0';
            message.style.transform = 'translateY(-20px)';
            setTimeout(() => {
                message.remove();
            }, 400);
        }, 5000);
    });
})();

