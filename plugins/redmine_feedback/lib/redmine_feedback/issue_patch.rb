# redmine_feedback/lib/redmine_feedback/issue_patch.rb

module RedmineFeedback
  module IssuePatch
    def self.included(base)
      base.send(:include, InstanceMethods)
    end

    module InstanceMethods
      def public_feedback_url
        Rails.application.routes.url_helpers.url_for(
          controller: 'feedback',
          action: 'vote',
          id: self.id,
          token: generate_feedback_token,
          only_path: false,
          host: Setting.host_name
        )
      end

      def feedback_record
        @feedback_record ||= Feedback.find_by(issue_id: id)
      end

      def feedback_rating
        feedback = feedback_record
        return unless feedback&.vote.present?

        Feedback.rating_value_for(feedback.vote)
      end

      def feedback_comment
        feedback_record&.vote_comment.to_s
      end

      private

      def generate_feedback_token
        Digest::SHA1.hexdigest("#{self.id}-#{self.created_on}-#{Redmine::Configuration['secret_token']}")
      end
    end
  end
end
