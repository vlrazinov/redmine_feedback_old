class AddFeedbackCustomField < ActiveRecord::Migration[6.0]
  def up
    field = IssueCustomField.create!(
      name: 'Оценка поддержки',
      field_format: 'string',
      is_for_all: true,
      is_filter: true,
      editable: true,
      visible: true,
      trackers: Tracker.all
    )

    Setting.plugin_redmine_feedback = {} unless Setting.plugin_redmine_feedback
    Setting.plugin_redmine_feedback['feedback_custom_field_id'] = field.id
  end

  def down
    field_id = Setting.plugin_redmine_feedback['feedback_custom_field_id']
    IssueCustomField.find_by(id: field_id)&.destroy
    Setting.plugin_redmine_feedback = Setting.plugin_redmine_feedback.merge('feedback_custom_field_id' => nil)
  end
end
