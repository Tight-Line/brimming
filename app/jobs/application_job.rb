# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Ensure jobs are not enqueued until the transaction commits.
  # This prevents race conditions where a job runs before the data it needs
  # has been committed to the database (important for single-database setups).
  self.enqueue_after_transaction_commit = :default

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
end
