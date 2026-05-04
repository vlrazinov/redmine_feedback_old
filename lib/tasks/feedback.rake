# redmine_feedback/lib/tasks/feedback.rake

namespace :redmine_feedback do
  desc 'Create feedback custom field'
  task create_custom_field: :environment do
    # Проверяем, существует ли уже поле
    field = IssueCustomField.find_by(name: 'Оценка поддержки')
    
    if field.nil?
      field = IssueCustomField.new(
        name: 'Оценка поддержки',
        field_format: 'list',
        possible_values: ['Хорошо', 'Нормально', 'Плохо'],
        is_for_all: true,
        is_filter: true,
        editable: true,
        visible: true,
        trackers: Tracker.all
      )
      
      if field.save
        # Сохраняем ID поля в настройках плагина
        Setting.plugin_redmine_feedback = {} unless Setting.plugin_redmine_feedback
        Setting.plugin_redmine_feedback['feedback_custom_field_id'] = field.id
        puts "Custom field 'Оценка поддержки' created with ID: #{field.id}"
      else
        puts "Error creating custom field: #{field.errors.full_messages.join(', ')}"
      end
    else
      field.update!(
        field_format: 'list',
        possible_values: ['Хорошо', 'Нормально', 'Плохо'],
        is_for_all: true,
        is_filter: true,
        visible: true,
        trackers: Tracker.all
      )
      puts "Custom field 'Оценка поддержки' already exists with ID: #{field.id}"
      Setting.plugin_redmine_feedback['feedback_custom_field_id'] = field.id
    end
  end
end
