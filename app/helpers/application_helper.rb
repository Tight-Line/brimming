module ApplicationHelper
  # Format token counts sensibly:
  # - Exact multiples of 1024: use K notation (1K, 2K, 8K)
  # - Everything else: exact number
  def format_tokens(count)
    return count.to_s if count < 1024

    if (count % 1024).zero?
      "#{count / 1024}K"
    else
      number_with_delimiter(count)
    end
  end

  # Bootstrap-style badge class for FAQ suggestion status
  def status_badge_class(status)
    case status.to_s
    when "pending" then "warning"
    when "approved" then "success"
    when "rejected" then "secondary"
    when "created" then "primary"
    else "secondary"
    end
  end
end
