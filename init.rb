require 'redmine'

# Регистрируем макрос
Redmine::WikiFormatting::Macros.register do
  desc "Inserts a link to the feedback form. Usage: {{feedback_link}}"
  macro :feedback_link do |obj, args|
    issue = nil
    
    if obj.is_a?(Issue)
      issue = obj
    elsif obj.is_a?(Journal)
      issue = obj.journalized if obj.respond_to?(:journalized) && obj.journalized.is_a?(Issue)
      issue ||= obj.issue if obj.respond_to?(:issue) && obj.issue.is_a?(Issue)
    elsif obj.respond_to?(:issue) && obj.issue.is_a?(Issue)
      issue = obj.issue
    end
    
    if issue && issue.is_a?(Issue)
      secret_token = Redmine::Configuration['secret_token']
      if secret_token.blank?
        Rails.logger.error "[Redmine Feedback] secret_token is not configured"
        return I18n.t(:label_feedback_link_error)
      end
      
      token = Digest::SHA1.hexdigest("#{issue.id}-#{issue.created_on}-#{secret_token}")
      url = "#{Setting.protocol}://#{Setting.host_name}/feedback/#{issue.id}/vote?token=#{token}"
      link_text = Setting.plugin_redmine_feedback['feedback_link_text'] || I18n.t(:label_feedback_link_text)
      "<a href='#{url}' class='feedback-link' target='_blank'>#{link_text}</a>".html_safe
    else
      I18n.t(:label_feedback_link_error)
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
  require_dependency 'redmine_feedback/issue_patch'
  require_dependency 'redmine_feedback/issue_query_patch'
  require_dependency 'redmine_feedback/queries_helper_patch'

  Issue.include RedmineFeedback::IssuePatch unless Issue.included_modules.include?(RedmineFeedback::IssuePatch)
  IssueQuery.include RedmineFeedback::IssueQueryPatch unless IssueQuery.included_modules.include?(RedmineFeedback::IssueQueryPatch)
  QueriesHelper.include RedmineFeedback::QueriesHelperPatch unless QueriesHelper.included_modules.include?(RedmineFeedback::QueriesHelperPatch)

  RedmineFeedback::CustomFieldsManager.ensure_custom_fields_exist!
end
