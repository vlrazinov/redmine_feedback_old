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

Rails.configuration.to_prepare do
  require_dependency 'redmine_feedback/custom_fields_manager'
  require_dependency 'redmine_feedback/hooks'
  RedmineFeedback::CustomFieldsManager.ensure_custom_fields_exist!
end
