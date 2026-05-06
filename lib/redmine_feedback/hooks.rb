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
      
      rating = custom_value.value
      comment = feedback_comment_for(issue)
      show_customer_vote(rating, comment)
    end
    
    def view_issues_show_details_bottom(context = {})
      issue = context[:issue]
      return '' unless issue
      
      feedback = Feedback.find_by(issue_id: issue.id)
      rating = feedback&.vote || feedback_rating_custom_value(issue)
      return '' unless rating.present?

      issue_fields_rows do |rows|
        rows.right I18n.t(:label_feedback_title),
                   show_customer_vote(rating, feedback_comment_for(issue)),
                   class: 'feedback support-rating'
      end
    end

    private

    def feedback_comment_for(issue)
      comment_custom_field_id = Setting.plugin_redmine_feedback['feedback_comment_custom_field_id']
      if comment_custom_field_id.present?
        comment_value = issue.custom_values.detect { |value| value.custom_field_id.to_s == comment_custom_field_id.to_s }
        return comment_value.value if comment_value&.value.present?
      end

      Feedback.find_by(issue_id: issue.id)&.vote_comment
    end

    def feedback_rating_custom_value(issue)
      feedback_field_id = Setting.plugin_redmine_feedback['feedback_custom_field_id']
      return unless feedback_field_id.present?

      issue.custom_value_for(feedback_field_id)&.value
    end
  end
end
