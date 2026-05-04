module RedmineFeedback
  module IssueQueryPatch
    def self.included(base)
      base.class_eval do
        alias_method :available_columns_without_feedback, :available_columns
        alias_method :available_columns, :available_columns_with_feedback

        alias_method :initialize_available_filters_without_feedback, :initialize_available_filters
        alias_method :initialize_available_filters, :initialize_available_filters_with_feedback

        alias_method :joins_for_order_statement_without_feedback, :joins_for_order_statement
        alias_method :joins_for_order_statement, :joins_for_order_statement_with_feedback
      end
    end

    def available_columns_with_feedback
      if @available_columns.blank?
        @available_columns = available_columns_without_feedback
        @available_columns << QueryColumn.new(:feedback_rating,
                                              caption: :label_feedback_title,
                                              sortable: "#{Feedback.table_name}.vote")
        @available_columns << QueryColumn.new(:feedback_comment,
                                              inline: false,
                                              caption: :label_feedback_comment)
      end

      @available_columns
    end

    def initialize_available_filters_with_feedback
      initialize_available_filters_without_feedback

      add_available_filter 'feedback.rating',
                           type: :list_optional,
                           name: l(:label_feedback_title),
                           values: [[l(:label_good), Feedback::VOTE_AWESOME.to_s],
                                    [l(:label_okay), Feedback::VOTE_JUSTOK.to_s],
                                    [l(:label_bad), Feedback::VOTE_NOTGOOD.to_s]]
      add_available_filter 'feedback.comment',
                           type: :text,
                           name: l(:label_feedback_comment)
    end

    def joins_for_order_statement_with_feedback(order_options)
      joins = joins_for_order_statement_without_feedback(order_options)
      feedback_joins = [joins].flatten.compact

      if order_options && order_options.include?("#{Feedback.table_name}.vote")
        feedback_joins << "LEFT OUTER JOIN #{Feedback.table_name} ON #{Issue.table_name}.id = #{Feedback.table_name}.issue_id"
      end

      feedback_joins.any? ? feedback_joins.join(' ') : nil
    end

    def sql_for_feedback_rating_field(_field, operator, value)
      compare = case operator
                when '=', '*' then 'IN'
                when '!', '!*' then 'NOT IN'
                end

      subquery = if %w[= !].include?(operator)
                   Feedback.where(vote: value).select(:issue_id).to_sql
                 else
                   Feedback.where.not(vote: nil).select(:issue_id).to_sql
                 end

      "(#{Issue.table_name}.id #{compare} (#{subquery}))"
    end

    def sql_for_feedback_comment_field(field, operator, value)
      case operator
      when '*'
        "#{Issue.table_name}.id IN (#{Feedback.where.not(vote_comment: [nil, '']).select(:issue_id).to_sql})"
      when '!*'
        "#{Issue.table_name}.id NOT IN (#{Feedback.where.not(vote_comment: [nil, '']).select(:issue_id).to_sql})"
      else
        "#{Issue.table_name}.id IN (SELECT #{Feedback.table_name}.issue_id FROM #{Feedback.table_name}" \
          " WHERE #{sql_for_field(field, operator, value, Feedback.table_name, 'vote_comment')})"
      end
    end
  end
end
