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

    expected_token = Digest::SHA1.hexdigest("#{@issue.id}-#{@issue.created_on}-#{Redmine::Configuration['secret_token']}")

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

    expected_token = Digest::SHA1.hexdigest("#{@issue.id}-#{@issue.created_on}-#{Redmine::Configuration['secret_token']}")
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
      @issue.save!
    end

    # Сохраняем голос и комментарий через модель Feedback
    feedback = Feedback.find_or_initialize_by(issue_id: @issue.id)
    feedback.update_vote!(vote_value, comment.presence)

    flash[:notice] = 'Спасибо! Ваша оценка сохранена.'
    redirect_to feedback_vote_path(@issue.id, token: token)
  end
end
