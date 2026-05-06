class Feedback < ApplicationRecord
  belongs_to :issue
  validates :issue_id, presence: true
  validates :issue_id, uniqueness: { message: 'Feedback already exists for this issue' }
  
  # Vote constants
  VOTE_NOTGOOD = 0
  VOTE_JUSTOK = 1
  VOTE_AWESOME = 2
  
  RATING_VALUES = {
    'good' => I18n.t(:label_good),
    'okay' => I18n.t(:label_okay),
    'bad' => I18n.t(:label_bad),
    VOTE_AWESOME.to_s => I18n.t(:label_good),
    VOTE_JUSTOK.to_s => I18n.t(:label_okay),
    VOTE_NOTGOOD.to_s => I18n.t(:label_bad)
  }.freeze

  VOTE_VALUES = {
    'good' => VOTE_AWESOME,
    'okay' => VOTE_JUSTOK,
    'bad' => VOTE_NOTGOOD
  }.freeze

  def self.rating_value_for(value)
    RATING_VALUES[value.to_s] || value
  end

  def self.vote_value_for(value)
    VOTE_VALUES[value.to_s]
  end
  
  # Виртуальное поле для получения значения оценки из кастомного поля задачи
  def rating_value
    custom_field_id = Setting.plugin_redmine_feedback['feedback_custom_field_id']
    if custom_field_id.present? && issue.present?
      issue.custom_value_for(custom_field_id)&.value
    end
  end
  
  # Возвращает текстовое представление голоса
  def vote_text
    case vote
    when VOTE_AWESOME
      I18n.t(:label_good)
    when VOTE_JUSTOK
      I18n.t(:label_okay)
    when VOTE_NOTGOOD
      I18n.t(:label_bad)
    else
      nil
    end
  end
  
  # Обновление голоса с комментарием. История пользовательских полей задачи
  # ведется стандартным журналом Redmine при сохранении Issue.
  def update_vote!(new_vote, comment = nil)
    transaction do
      update!(vote: new_vote, vote_comment: comment)
    end
  rescue ActiveRecord::RecordNotUnique => e
    Rails.logger.error "[Redmine Feedback] Race condition detected while saving feedback for issue #{issue_id}: #{e.message}"
    raise
  end
end
