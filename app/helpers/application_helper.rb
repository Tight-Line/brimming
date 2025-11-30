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
end
