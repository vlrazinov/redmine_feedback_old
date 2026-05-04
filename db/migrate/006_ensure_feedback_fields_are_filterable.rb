class EnsureFeedbackFieldsAreFilterable < ActiveRecord::Migration[6.0]
  RATING_VALUES = ['Хорошо', 'Нормально', 'Плохо'].freeze

  def up
    settings = Setting.plugin_redmine_feedback || {}

    if settings['feedback_custom_field_id'].present?
      field = IssueCustomField.find_by(id: settings['feedback_custom_field_id'])
      if field
        field.field_format = 'list'
        field.possible_values = RATING_VALUES
        field.is_filter = true
        field.is_for_all = true
        field.visible = true
        field.trackers = Tracker.all
        field.save!
      end
    end

    if settings['feedback_comment_custom_field_id'].present?
      field = IssueCustomField.find_by(id: settings['feedback_comment_custom_field_id'])
      if field
        field.is_filter = true
        field.is_for_all = true
        field.visible = true
        field.trackers = Tracker.all
        field.save!
      end
    end
  end

  def down
  end
end
