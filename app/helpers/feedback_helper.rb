module FeedbackHelper
  def rating_text_for(value)
    case value
    when Feedback::VOTE_AWESOME, Feedback::VOTE_AWESOME.to_s then I18n.t(:label_good)
    when Feedback::VOTE_JUSTOK, Feedback::VOTE_JUSTOK.to_s then I18n.t(:label_okay)
    when Feedback::VOTE_NOTGOOD, Feedback::VOTE_NOTGOOD.to_s then I18n.t(:label_bad)
    when 'good', 'Хорошо' then I18n.t(:label_good)
    when 'okay', 'Нормально' then I18n.t(:label_okay)
    when 'bad', 'Плохо' then I18n.t(:label_bad)
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

    comment_custom_field_id = Setting.plugin_redmine_feedback['feedback_comment_custom_field_id']
    comment = if comment_custom_field_id.present?
                issue.custom_value_for(comment_custom_field_id)&.value
              end
    comment ||= Feedback.find_by(issue_id: issue.id)&.vote_comment

    text = rating_text_for(rating_value)
    
    if comment.present?
      content_tag(:span, text,
                  title: ERB::Util.html_escape(comment.to_s.squish),
                  class: 'feedback-rating',
                  data: { feedback_tooltip: true })
    else
      text
    end
  end
  
  # Отображает оценку с комментарием в виде всплывающей подсказки (tooltip)
  # Идентично реализации в helpdesk_votes (show_customer_vote)
  # vote - значение оценки, title - текст комментария для tooltip
  def show_customer_vote(vote, title = nil)
    return ''.html_safe unless vote.present?
    
    vote_text = case vote.to_i
                when Feedback::VOTE_AWESOME then I18n.t(:label_good)
                when Feedback::VOTE_JUSTOK then I18n.t(:label_okay)
                when Feedback::VOTE_NOTGOOD then I18n.t(:label_bad)
                else vote.to_s
                end
    
    if title.present?
      # Создаем span с атрибутом title для tooltip (идентично helpdesk_votes)
      content_tag(:span, vote_text,
                  title: ERB::Util.html_escape(title.to_s.squish),
                  class: 'feedback-rating',
                  data: { feedback_tooltip: true })
    else
      vote_text
    end
  end
end
