module FeedbackHelper
  def rating_text_for(value)
    case value
    when Feedback::VOTE_AWESOME, Feedback::VOTE_AWESOME.to_s then 'Хорошо'
    when Feedback::VOTE_JUSTOK, Feedback::VOTE_JUSTOK.to_s then 'Нормально'
    when Feedback::VOTE_NOTGOOD, Feedback::VOTE_NOTGOOD.to_s then 'Плохо'
    when 'Хорошо', 'good' then 'Хорошо'
    when 'Нормально', 'okay' then 'Нормально'
    when 'Плохо', 'bad' then 'Плохо'
    else value.to_s
    end
  end

  # Форматирует значение оценки, добавляя комментарий в title (всплывающую подсказку)
  # Возвращает HTML с подчеркнутым текстом и tooltip при наличии комментария
  def format_feedback_with_tooltip(issue)
    custom_field_id = Setting.plugin_redmine_feedback['feedback_custom_field_id']
    
    return '-' unless custom_field_id.present?

    # Получаем значение оценки из кастомного поля
    rating_value = issue.custom_value_for(custom_field_id)&.value
    
    return '-' unless rating_value.present?

    # Получаем комментарий из таблицы feedbacks (поле vote_comment)
    feedback = Feedback.find_by(issue_id: issue.id)
    comment = feedback&.vote_comment

    text = rating_text_for(rating_value)
    
    if comment.present?
      # Экранируем специальные символы для атрибута title
      escaped_comment = comment.to_s.gsub('"', '&quot;').gsub("\n", ' ').gsub("\r", '')
      content_tag(:span, text, 
                  title: escaped_comment, 
                  style: "text-decoration: underline dotted; cursor: help; border-bottom: 1px dotted #999;")
    else
      text
    end
  end
end
