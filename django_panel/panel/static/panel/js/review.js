/**
 * Review Management JavaScript
 * Yorum yanıt formu toggle işlevselliği
 */

function toggleReplyForm(reviewId) {
    'use strict';
    const formSection = document.getElementById('reply-form-' + reviewId);
    if (formSection) {
        if (formSection.style.display === 'none') {
            formSection.style.display = 'block';
        } else {
            formSection.style.display = 'none';
        }
    }
}

