# frozen_string_literal: true

# Service for splitting text into overlapping chunks for RAG embedding.
#
# Chunks are created with configurable size (in tokens) and overlap (as percentage).
# The service attempts to break at sentence boundaries when possible.
#
# Usage:
#   service = ChunkingService.new(provider)
#   chunks = service.chunk_text(text)
#   # => [{ content: "...", token_count: 450, position: "start" }, ...]
#
class ChunkingService
  # Approximate characters per token (conservative estimate)
  CHARS_PER_TOKEN = EmbeddingProvider::CHARS_PER_TOKEN

  # Sentence-ending punctuation for splitting
  SENTENCE_ENDINGS = /(?<=[.!?])\s+/

  attr_reader :chunk_size, :chunk_overlap_tokens

  def initialize(provider)
    @chunk_size = provider.chunk_size
    @chunk_overlap_tokens = provider.chunk_overlap_tokens
  end

  # Split text into overlapping chunks
  # Returns array of hashes with :content, :token_count, and :position
  def chunk_text(text)
    return [] if text.blank?

    # Normalize whitespace
    text = text.strip.gsub(/\s+/, " ")

    # Calculate target sizes in characters
    target_chars = @chunk_size * CHARS_PER_TOKEN
    overlap_chars = @chunk_overlap_tokens * CHARS_PER_TOKEN

    # If text fits in one chunk, return it
    if text.length <= target_chars
      return [ build_chunk(text, "only") ]
    end

    chunks = []
    position = 0
    chunk_number = 0

    while position < text.length
      # Determine chunk end position
      end_pos = [ position + target_chars, text.length ].min

      # If this isn't the last chunk, try to break at a sentence boundary
      if end_pos < text.length
        end_pos = find_break_point(text, position, end_pos, target_chars)
      end

      # Extract chunk content
      chunk_content = text[position...end_pos].strip

      # Determine position label
      pos_label = if chunk_number == 0
                    "start"
      elsif end_pos >= text.length
                    "end"
      else
                    "middle"
      end

      chunks << build_chunk(chunk_content, pos_label)

      # Move position forward, accounting for overlap
      # For the next chunk, start overlap_chars before where we ended
      # But ensure we always make forward progress
      new_position = end_pos - overlap_chars

      # Ensure we always move forward by at least half the target chunk size
      min_advance = (target_chars * 0.5).to_i
      if new_position <= position
        new_position = position + min_advance
      end

      position = new_position

      # Stop if we've reached the end
      break if position >= text.length

      chunk_number += 1
    end

    chunks
  end

  private

  def build_chunk(content, position)
    {
      content: content,
      token_count: estimate_tokens(content),
      position: position
    }
  end

  def estimate_tokens(text)
    (text.length.to_f / CHARS_PER_TOKEN).ceil
  end

  # Try to find a sentence boundary near the target end position
  # Falls back to word boundary if no sentence boundary found
  def find_break_point(text, start_pos, end_pos, target_chars)
    # Look for sentence boundaries in the last 20% of the chunk
    search_start = end_pos - (target_chars * 0.2).to_i
    search_start = [ search_start, start_pos ].max

    search_region = text[search_start...end_pos]

    # Find the last sentence ending in the search region using reverse search
    # This is more efficient than collecting all matches when we only need the last one
    last_match_pos = find_last_sentence_ending(search_region)

    if last_match_pos
      # Return position after the sentence ending (skip the whitespace)
      return search_start + last_match_pos + 1
    end

    # Fall back to word boundary
    find_word_boundary(text, end_pos)
  end

  # Find the position of the last sentence ending in the text
  # Returns the position after the punctuation (at the whitespace), or nil if not found
  def find_last_sentence_ending(text)
    # Search backwards through the text for sentence endings
    # We look for punctuation followed by whitespace
    pos = text.length - 1

    while pos > 0
      # Check if we're at whitespace preceded by sentence-ending punctuation
      if text[pos] =~ /\s/ && pos > 0 && text[pos - 1] =~ /[.!?]/
        return pos
      end
      pos -= 1
    end

    nil
  end

  def find_word_boundary(text, pos)
    # If we're at end of text or at a space, we're done
    return pos if pos >= text.length
    return pos if text[pos] == " "

    # Look backward for a space (up to 50 chars)
    50.times do |i|
      check_pos = pos - i
      return check_pos + 1 if check_pos > 0 && text[check_pos] == " "
    end

    # No space found, just break at position
    pos
  end
end
