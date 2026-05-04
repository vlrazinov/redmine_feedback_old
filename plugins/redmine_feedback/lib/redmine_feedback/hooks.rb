module RedmineFeedback
  class Hooks < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(context)
      stylesheet_link_tag('feedback', :plugin => 'redmine_feedback') +
        javascript_include_tag('feedback', :plugin => 'redmine_feedback')
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
      
      rating_html(issue, custom_value.value)
    end
    
    def view_issues_show_details_bottom(context = {})
      issue = context[:issue]
      return '' unless issue
      
      feedback_field_id = Setting.plugin_redmine_feedback['feedback_custom_field_id']
      return '' unless feedback_field_id
      
      custom_value = issue.custom_value_for(feedback_field_id)
      rating = custom_value&.value
      return '' unless rating.present?
      
      decorate_rating_field_script(issue, feedback_field_id, rating)
    end

    private

    def rating_html(issue, rating)
      return ''.html_safe unless rating.present?

      rating_text = rating_text_for(rating)
      comment = feedback_comment_for(issue)
      css_class = "feedback-rating feedback-#{rating_css_class(rating)}"

      if comment.present?
        tag_options = {
          class: css_class,
          title: "#{I18n.t(:label_comment)}: #{comment.to_s.squish}",
          data: { feedback_tooltip: true }
        }
      else
        tag_options = { class: css_class }
      end

      content_tag(:span, rating_text, tag_options)
    end

    def rating_text_for(rating)
      case rating
      when 'good', 'Хорошо' then I18n.t(:label_good)
      when 'okay', 'Нормально' then I18n.t(:label_okay)
      when 'bad', 'Плохо' then I18n.t(:label_bad)
      else
        rating.to_s
      end
    end

    def rating_css_class(rating)
      case rating
      when 'good', 'Хорошо' then 'good'
      when 'okay', 'Нормально' then 'okay'
      when 'bad', 'Плохо' then 'bad'
      else
        'unknown'
      end
    end

    def feedback_comment_for(issue)
      comment_custom_field_id = Setting.plugin_redmine_feedback['feedback_comment_custom_field_id']
      if comment_custom_field_id.present?
        comment_value = issue.custom_values.detect { |value| value.custom_field_id.to_s == comment_custom_field_id.to_s }
        return comment_value.value if comment_value&.value.present?
      end

      Feedback.find_by(issue_id: issue.id)&.vote_comment
    end

    def decorate_rating_field_script(issue, feedback_field_id, rating)
      comment = feedback_comment_for(issue).to_s.squish
      title = comment.present? ? "#{I18n.t(:label_comment)}: #{comment}" : ''
      selector = ".cf_#{feedback_field_id.to_i} .value"

      script = <<~JAVASCRIPT
        (function decorateFeedbackRating() {
          var ratingValue = document.querySelector(#{selector.to_json});
          if (!ratingValue) return;

          ratingValue.textContent = #{rating_text_for(rating).to_json};
          ratingValue.classList.add('feedback-rating-field', 'feedback-#{rating_css_class(rating)}');

          if (#{comment.present?.to_json}) {
            ratingValue.setAttribute('title', #{title.to_json});
            ratingValue.setAttribute('data-feedback-tooltip', 'true');
            if (typeof initFeedbackTooltips === 'function') {
              initFeedbackTooltips();
            }
          }
        }());
      JAVASCRIPT

      javascript_tag(script)
    end
  end
end
