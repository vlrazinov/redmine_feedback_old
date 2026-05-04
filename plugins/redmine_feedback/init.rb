require 'redmine'

# Регистрируем макрос
Redmine::WikiFormatting::Macros.register do
  desc "Inserts a link to the feedback form. Usage: {{feedback_link}}"
  macro :feedback_link do |obj, args|
    issue = nil
    
    if obj.is_a?(Issue)
      issue = obj
    elsif obj.is_a?(Journal)
      issue = obj.issue if obj.issue.is_a?(Issue)
      issue ||= obj.journalized if obj.journalized.is_a?(Issue)
    elsif obj.respond_to?(:issue) && obj.issue.is_a?(Issue)
      issue = obj.issue
    end
    
    if issue && issue.is_a?(Issue)
      token = Digest::SHA1.hexdigest("#{issue.id}-#{issue.created_on}-#{Redmine::Configuration['secret_token']}")
      url = "#{Setting.protocol}://#{Setting.host_name}/feedback/#{issue.id}/vote?token=#{token}"
      link_text = Setting.plugin_redmine_feedback['feedback_link_text'] || 'Оценить поддержку'
      "<a href='#{url}' class='feedback-link' target='_blank'>#{link_text}</a>".html_safe
    else
      "Ссылка для оценки доступна только в задачах"
    end
  end
end

# Флаг для однократной инициализации
$redmine_feedback_initialized = false

# Инициализируем поля после подготовки окружения
Rails.configuration.to_prepare do
  unless $redmine_feedback_initialized
    # Создаём поля только один раз при загрузке приложения
    begin
      # Проверяем и создаём поле для оценки
      field_id = Setting.plugin_redmine_feedback['feedback_custom_field_id']
      
      rating_values = ['Хорошо', 'Нормально', 'Плохо']

      if field_id.present? && (configured_field = IssueCustomField.find_by(id: field_id))&.name == 'Оценка поддержки'
        configured_field.update!(
          field_format: 'list',
          possible_values: rating_values,
          is_filter: true,
          is_for_all: true,
          visible: true,
          trackers: Tracker.all
        )
      else
        existing_field = IssueCustomField.find_by(name: 'Оценка поддержки')
        if existing_field
          existing_field.update!(
            field_format: 'list',
            possible_values: rating_values,
            is_filter: true,
            is_for_all: true,
            visible: true,
            trackers: Tracker.all
          )
          Setting.plugin_redmine_feedback = Setting.plugin_redmine_feedback.merge(
            'feedback_custom_field_id' => existing_field.id.to_s
          )
        else
          field = IssueCustomField.create!(
            name: 'Оценка поддержки',
            field_format: 'list',
            possible_values: rating_values,
            is_for_all: true,
            is_filter: true,
            editable: true,
            visible: true,
            trackers: Tracker.all
          )
          Setting.plugin_redmine_feedback = Setting.plugin_redmine_feedback.merge(
            'feedback_custom_field_id' => field.id.to_s
          )
        end
      end
      
      # Проверяем и создаём поле для комментария
      comment_field_id = Setting.plugin_redmine_feedback['feedback_comment_custom_field_id']
      
      if comment_field_id.present? && (configured_comment_field = IssueCustomField.find_by(id: comment_field_id))&.name == 'Комментарий к оценке поддержки'
        configured_comment_field.update!(
          is_filter: true,
          is_for_all: true,
          visible: true,
          trackers: Tracker.all
        )
      else
        existing_comment_field = IssueCustomField.find_by(name: 'Комментарий к оценке поддержки')
        if existing_comment_field
          existing_comment_field.update!(
            is_filter: true,
            is_for_all: true,
            visible: true,
            trackers: Tracker.all
          )
          Setting.plugin_redmine_feedback = Setting.plugin_redmine_feedback.merge(
            'feedback_comment_custom_field_id' => existing_comment_field.id.to_s
          )
        else
          comment_field = IssueCustomField.create!(
            name: 'Комментарий к оценке поддержки',
            field_format: 'text',
            is_for_all: true,
            is_filter: true,
            editable: true,
            visible: true,
            trackers: Tracker.all
          )
          Setting.plugin_redmine_feedback = Setting.plugin_redmine_feedback.merge(
            'feedback_comment_custom_field_id' => comment_field.id.to_s
          )
        end
      end
      
      $redmine_feedback_initialized = true
    rescue => e
      Rails.logger.error "[Redmine Feedback] Error initializing custom fields: #{e.message}"
    end
  end
end

Redmine::Plugin.register :redmine_feedback do
  name 'Redmine Feedback plugin'
  author 'Vladislav Razinov'
  description 'Adds universal feedback/voting mechanism for any issue type.'
  version '1.0.1'
  
  permission :view_feedback, { :feedback => [:vote] }, :public => true
  permission :submit_feedback, { :feedback => [:submit] }, :public => true

  settings :default => { 
    'feedback_custom_field_id' => nil,
    'feedback_comment_custom_field_id' => nil,
    'feedback_link_text' => 'Оценить поддержку'
  }, :partial => 'settings/feedback_settings'
end
