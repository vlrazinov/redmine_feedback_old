class FeedbackController < ApplicationController
  skip_before_action :check_if_login_required, only: [:vote, :submit]
  layout 'base'
  
  def vote
    @issue = Issue.find_by(id: params[:id])
    token = params[:token]

    if @issue.nil?
      render_404
      return
    end

    secret_token = Redmine::Configuration['secret_token']
    if secret_token.blank?
      Rails.logger.error "[Redmine Feedback] secret_token is not configured"
      render_404
      return
    end

    expected_token = Digest::SHA1.hexdigest("#{@issue.id}-#{@issue.created_on}-#{secret_token}")

    if token != expected_token
      render_404
      return
    end

    custom_field_id = Setting.plugin_redmine_feedback['feedback_custom_field_id']
    if custom_field_id.present?
      @existing_feedback = @issue.custom_value_for(custom_field_id)&.value
    end
    @feedback = Feedback.find_by(issue_id: @issue.id)
    @existing_comment = @feedback&.vote_comment
    @existing_vote = @feedback&.vote

    # Также получаем комментарий из custom field
    comment_custom_field_id = Setting.plugin_redmine_feedback['feedback_comment_custom_field_id']
    if comment_custom_field_id.present?
      @existing_comment ||= @issue.custom_value_for(comment_custom_field_id)&.value
    end
  end

  def submit
    @issue = Issue.find_by(id: params[:id])
    token = params[:token]

    if @issue.nil?
      render_404
      return
    end

    secret_token = Redmine::Configuration['secret_token']
    if secret_token.blank?
      Rails.logger.error "[Redmine Feedback] secret_token is not configured"
      render_404
      return
    end

    expected_token = Digest::SHA1.hexdigest("#{@issue.id}-#{@issue.created_on}-#{secret_token}")
    if token != expected_token
      render_404
      return
    end

    rating = params[:rating]
    comment = params[:comment].to_s
    rating_value = Feedback.rating_value_for(rating)
    vote_value = Feedback.vote_value_for(rating)

    custom_field_values = {}
    rating_custom_field_id = Setting.plugin_redmine_feedback['feedback_custom_field_id']
    if rating_custom_field_id.present? && rating.present?
      custom_field_values[rating_custom_field_id.to_s] = rating_value
    end

    comment_custom_field_id = Setting.plugin_redmine_feedback['feedback_comment_custom_field_id']
    if comment_custom_field_id.present?
      custom_field_values[comment_custom_field_id.to_s] = comment
    end

    if custom_field_values.any?
      @issue.init_journal(User.current)
      @issue.custom_field_values = custom_field_values
      unless @issue.save
        Rails.logger.error "[Redmine Feedback] Failed to save issue #{@issue.id}: #{@issue.errors.full_messages.join(', ')}"
        flash[:error] = I18n.t(:notice_failed_to_save_issue)
        redirect_to feedback_vote_path(@issue.id, token: token)
        return
      end
    end

    # Сохраняем голос и комментарий через модель Feedback
    begin
      feedback = Feedback.find_or_initialize_by(issue_id: @issue.id)
      feedback.update_vote!(vote_value, comment.presence)
      flash[:notice] = I18n.t(:notice_feedback_submitted)
    rescue => e
      Rails.logger.error "[Redmine Feedback] Error saving feedback for issue #{@issue.id}: #{e.message}"
      flash[:error] = I18n.t(:notice_failed_to_save_feedback)
    end
    
    redirect_to feedback_vote_path(@issue.id, token: token)
  end
end
