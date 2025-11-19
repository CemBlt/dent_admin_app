/**
 * Tema Yönetimi
 * localStorage'dan tema tercihini okur ve tema değiştirme işlevselliği sağlar
 */
(function() {
    'use strict';
    
    // localStorage'dan tema tercihini oku (default: dark)
    const savedTheme = localStorage.getItem('theme') || 'dark';
    document.documentElement.setAttribute('data-theme', savedTheme);
    
    // Aktif butonu güncelle
    const themeButtons = document.querySelectorAll('.theme-btn');
    themeButtons.forEach(btn => {
        if (btn.dataset.theme === savedTheme) {
            btn.classList.add('active');
        } else {
            btn.classList.remove('active');
        }
    });
    
    // Tema değiştirme
    themeButtons.forEach(btn => {
        btn.addEventListener('click', function() {
            const theme = this.dataset.theme;
            document.documentElement.setAttribute('data-theme', theme);
            localStorage.setItem('theme', theme);
            
            // Aktif butonu güncelle
            themeButtons.forEach(b => b.classList.remove('active'));
            this.classList.add('active');
        });
    });
})();

