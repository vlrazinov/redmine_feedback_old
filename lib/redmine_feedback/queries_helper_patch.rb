module RedmineFeedback
  module QueriesHelperPatch
    def column_value(column, list_object, value)
      if list_object.is_a?(Issue) && column.name == :feedback_rating
        feedback_rating_column(list_object)
      elsif list_object.is_a?(Issue) && column.name == :feedback_comment
        textilizable(list_object.feedback_comment.to_s)
      else
        super
      end
    end

    private

    def feedback_rating_column(issue)
      rating = issue.feedback_rating
      return '' unless rating.present?

      options = {
        class: "feedback-rating feedback-#{feedback_rating_css_class(rating)}"
      }

      if issue.feedback_comment.present?
        options[:title] = "#{l(:label_comment)}: #{issue.feedback_comment.squish}"
        options[:data] = { feedback_tooltip: true }
      end

      content_tag(:span, rating, options)
    end

    def feedback_rating_css_class(rating)
      case rating
      when 'Хорошо' then 'good'
      when 'Нормально' then 'okay'
      when 'Плохо' then 'bad'
      else
        'unknown'
      end
    end
  end
end
