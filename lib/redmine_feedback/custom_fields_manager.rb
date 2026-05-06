module RedmineFeedback
  class CustomFieldsManager
    RATING_VALUES = %w[Хорошо Нормально Плохо].freeze

    # Вызывается при инициализации плагина для создания и привязки полей
    def self.ensure_custom_fields_exist!
      ensure_feedback_field!
      ensure_feedback_comment_field!
    end

    private

    def self.ensure_feedback_field!
      field_id = Setting.plugin_redmine_feedback['feedback_custom_field_id']
      
      # Если поле уже настроено, проверяем существует ли оно
      if field_id.present?
        existing_field = IssueCustomField.find_by(id: field_id)
        if existing_field && (existing_field.name == 'Оценка поддержки' || existing_field.name == 'Обратная связь')
          configure_feedback_field!(existing_field)
          return
        end
      end
      
      # Ищем поле по имени (старое или новое)
      existing_field = IssueCustomField.find_by(name: 'Оценка поддержки')
      if existing_field
        # Переименовываем поле
        existing_field.name = 'Обратная связь'
        existing_field.save!
        configure_feedback_field!(existing_field)
        Setting.plugin_redmine_feedback = Setting.plugin_redmine_feedback.merge(
          'feedback_custom_field_id' => existing_field.id.to_s
        )
        return
      end
      
      # Ищем новое поле
      existing_field = IssueCustomField.find_by(name: 'Обратная связь')
      if existing_field
        configure_feedback_field!(existing_field)
        Setting.plugin_redmine_feedback = Setting.plugin_redmine_feedback.merge(
          'feedback_custom_field_id' => existing_field.id.to_s
        )
        return
      end
      
      # Создаём новое поле только если есть трекеры
      tracker_ids = Tracker.pluck(:id)
      return if tracker_ids.empty?
      
      field = IssueCustomField.create!(
        name: 'Обратная связь',
        field_format: 'list',
        possible_values: RATING_VALUES,
        is_for_all: true,
        is_filter: true,
        editable: true,
        visible: true,
        trackers: Tracker.where(id: tracker_ids)
      )
      
      Setting.plugin_redmine_feedback = Setting.plugin_redmine_feedback.merge(
        'feedback_custom_field_id' => field.id.to_s
      )
    rescue => e
      Rails.logger.error "[Redmine Feedback] Error creating feedback custom field: #{e.message}"
    end

    def self.ensure_feedback_comment_field!
      field_id = Setting.plugin_redmine_feedback['feedback_comment_custom_field_id']
      
      # Если поле уже настроено, проверяем существует ли оно
      if field_id.present?
        existing_field = IssueCustomField.find_by(id: field_id)
        if existing_field && (existing_field.name == 'Комментарий к оценке поддержки' || existing_field.name == 'Комментарий к обратной связи')
          configure_feedback_comment_field!(existing_field)
          return
        end
      end
      
      # Ищем поле по имени (старое или новое)
      existing_field = IssueCustomField.find_by(name: 'Комментарий к оценке поддержки')
      if existing_field
        # Переименовываем поле
        existing_field.name = 'Комментарий к обратной связи'
        existing_field.save!
        configure_feedback_comment_field!(existing_field)
        Setting.plugin_redmine_feedback = Setting.plugin_redmine_feedback.merge(
          'feedback_comment_custom_field_id' => existing_field.id.to_s
        )
        return
      end
      
      # Ищем новое поле
      existing_field = IssueCustomField.find_by(name: 'Комментарий к обратной связи')
      if existing_field
        configure_feedback_comment_field!(existing_field)
        Setting.plugin_redmine_feedback = Setting.plugin_redmine_feedback.merge(
          'feedback_comment_custom_field_id' => existing_field.id.to_s
        )
        return
      end
      
      # Создаём новое поле только если есть трекеры
      tracker_ids = Tracker.pluck(:id)
      return if tracker_ids.empty?
      
      field = IssueCustomField.create!(
        name: 'Комментарий к обратной связи',
        field_format: 'text',
        is_for_all: true,
        is_filter: true,
        editable: true,
        visible: true,
        trackers: Tracker.where(id: tracker_ids)
      )
      
      Setting.plugin_redmine_feedback = Setting.plugin_redmine_feedback.merge(
        'feedback_comment_custom_field_id' => field.id.to_s
      )
    rescue => e
      Rails.logger.error "[Redmine Feedback] Error creating feedback comment custom field: #{e.message}"
    end

    def self.configure_feedback_field!(field)
      all_tracker_ids = Tracker.pluck(:id).sort
      tracker_ids = field.tracker_ids.sort
      
      needs_update = false
      
      if field.field_format != 'list' || field.possible_values != RATING_VALUES
        field.field_format = 'list'
        field.possible_values = RATING_VALUES
        needs_update = true
      end
      
      unless field.is_filter && field.is_for_all && field.visible
        field.is_filter = true
        field.is_for_all = true
        field.visible = true
        needs_update = true
      end
      
      if tracker_ids != all_tracker_ids
        field.trackers = Tracker.where(id: all_tracker_ids)
        needs_update = true
      end
      
      field.save! if needs_update && field.changed?
    end

    def self.configure_feedback_comment_field!(field)
      all_tracker_ids = Tracker.pluck(:id).sort
      tracker_ids = field.tracker_ids.sort
      
      needs_update = false
      
      unless field.is_filter && field.is_for_all && field.visible
        field.is_filter = true
        field.is_for_all = true
        field.visible = true
        needs_update = true
      end
      
      if tracker_ids != all_tracker_ids
        field.trackers = Tracker.where(id: all_tracker_ids)
        needs_update = true
      end
      
      field.save! if needs_update && field.changed?
    end
  end
end
