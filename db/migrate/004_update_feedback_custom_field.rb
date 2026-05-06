class UpdateFeedbackCustomField < ActiveRecord::Migration[6.0]
  def up
    field_id = Setting.plugin_redmine_feedback['feedback_custom_field_id']
    if field_id.present?
      field = IssueCustomField.find_by(id: field_id)
      if field
        field.field_format = 'list'
        field.possible_values = ['Хорошо', 'Нормально', 'Плохо']
        field.save!
      end
    end
  end

  def down
    # Не меняем обратно, так как это обновление
  end
end
