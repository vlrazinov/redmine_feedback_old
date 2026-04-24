module RedmineFeedback
  class Hooks < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(context)
      stylesheet_link_tag('feedback', :plugin => 'redmine_feedback')
    end
    
    # Этот хук вызывается при отображении значений кастомных полей
    # Мы перехватываем его, чтобы добавить tooltip к нашему полю оценки
    def view_custom_fields_values_issue(context={})
      issue = context[:issue]
      custom_field = context[:custom_field]
      return '' unless issue && custom_field
      
      feedback_field_id = Setting.plugin_redmine_feedback['feedback_custom_field_id']
      return '' unless feedback_field_id
      return '' unless custom_field.id.to_s == feedback_field_id.to_s
      
      # Находим значение нашего поля
      custom_value = issue.custom_values.detect { |v| v.custom_field_id.to_s == feedback_field_id.to_s }
      return '' unless custom_value.present?
      
      rating = custom_value.value
      return '' unless rating.present?
      
      rating_text = case rating
                    when 'good', 'Хорошо' then I18n.t(:label_good)
                    when 'okay', 'Нормально' then I18n.t(:label_okay)
                    when 'bad', 'Плохо' then I18n.t(:label_bad)
                    else rating.to_s
                    end
      
      # Получаем комментарий из custom field
      comment_custom_field_id = Setting.plugin_redmine_feedback['feedback_comment_custom_field_id']
      comment = nil
      if comment_custom_field_id.present?
        comment_value = issue.custom_values.detect { |v| v.custom_field_id.to_s == comment_custom_field_id.to_s }
        comment = comment_value&.value
      end
      # Fallback to feedback model
      feedback = Feedback.find_by(issue_id: issue.id)
      comment ||= feedback&.vote_comment if feedback
      
      # Формируем tooltip с комментарием - всегда показываем, даже если комментария нет
      tooltip_text = comment.present? ? comment.to_s.gsub("\n", ' ').gsub("\r", ' ').gsub('"', '&quot;').gsub("'", '&#39;') : ''
      tooltip = "#{I18n.t(:label_comment)}: #{tooltip_text}"
      
      # Возвращаем HTML с подсказкой - оборачиваем в span с title
      html = "<span class=\"feedback-rating-tooltip\" title=\"#{tooltip}\" style=\"cursor: help; text-decoration: underline dotted;\" data-comment=\"#{tooltip_text}\">#{rating_text}</span>"
      return html.html_safe
    end
    
    def view_issues_show_details_bottom(context = {})
      issue = context[:issue]
      return '' unless issue
      
      feedback_field_id = Setting.plugin_redmine_feedback['feedback_custom_field_id']
      return '' unless feedback_field_id
      
      custom_value = issue.custom_value_for(feedback_field_id)
      rating = custom_value&.value
      return '' unless rating.present?
      
      rating_text = case rating
                    when 'good', 'Хорошо' then I18n.t(:label_good)
                    when 'okay', 'Нормально' then I18n.t(:label_okay)
                    when 'bad', 'Плохо' then I18n.t(:label_bad)
                    else rating.to_s
                    end
      
      # Получаем комментарий из custom field
      comment_custom_field_id = Setting.plugin_redmine_feedback['feedback_comment_custom_field_id']
      comment = nil
      if comment_custom_field_id.present?
        comment_value = issue.custom_values.detect { |v| v.custom_field_id.to_s == comment_custom_field_id.to_s }
        comment = comment_value&.value
      end
      # Fallback to feedback model
      feedback = Feedback.find_by(issue_id: issue.id)
      comment ||= feedback&.vote_comment if feedback
      
      # Формируем tooltip с комментарием
      comment_html = ''
      if comment.present?
        # Очищаем комментарий от переносов строк и экранируем спецсимволы для HTML атрибута
        tooltip_text = comment.to_s.gsub("\n", ' ').gsub("\r", ' ').gsub('"', '&quot;').gsub("'", '&#39;')
        tooltip = "#{I18n.t(:label_comment)}: #{tooltip_text}"
        title_attr = "title=\"#{tooltip}\""
        style_attr = "style=\"cursor: help; text-decoration: underline dotted;\""
        escaped_comment = ERB::Util.html_escape(comment.to_s).gsub("\n", '<br>').html_safe
        comment_html = <<-HTML
          <div class="feedback-comment" style="margin-top: 6px; color: #333; font-size: 0.95em;">
            <strong>#{I18n.t(:label_comment)}:</strong>
            <span>#{escaped_comment}</span>
          </div>
        HTML
      else
        title_attr = ""
        style_attr = ""
      end
      
      html = <<-HTML
        <div class="feedback-info" style="margin-top: 10px;">
          <strong>⭐ Оценка поддержки:</strong>
          <span class="feedback-rating feedback-#{rating}" #{style_attr} #{title_attr}>
            #{rating_text}
          </span>
          #{comment_html}
        </div>
      HTML
      
      html.html_safe
    end
  end
end
