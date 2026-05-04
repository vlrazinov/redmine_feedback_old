// redmine_feedback/assets/javascripts/feedback.js

document.addEventListener('DOMContentLoaded', function() {
  // Добавляем обработчик для ссылок на форму обратной связи
  var feedbackLinks = document.querySelectorAll('.feedback-link');
  feedbackLinks.forEach(function(link) {
    link.addEventListener('click', function(e) {
      // Открываем в новой вкладке
      // Стандартное поведение уже target="_blank"
    });
  });
});

function initFeedbackTooltips() {
  if (window.jQuery && jQuery.fn.tooltip) {
    jQuery('.feedback-rating-field[title], .feedback-rating[title], .label[data-feedback-tooltip][title]').tooltip({
      show: {
        delay: 400
      },
      position: {
        my: 'center bottom-5',
        at: 'center top'
      }
    });
  }
}

document.addEventListener('DOMContentLoaded', initFeedbackTooltips);
