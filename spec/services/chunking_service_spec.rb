# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChunkingService do
  let(:provider) { build(:embedding_provider, :openai) }

  before do
    # Set predictable chunking config
    provider.chunk_size = 100     # tokens
    provider.chunk_overlap = 10   # 10% overlap
  end

  describe "#chunk_text" do
    context "with empty or nil text" do
      it "returns empty array for nil" do
        service = described_class.new(provider)
        expect(service.chunk_text(nil)).to eq([])
      end

      it "returns empty array for empty string" do
        service = described_class.new(provider)
        expect(service.chunk_text("")).to eq([])
      end

      it "returns empty array for whitespace only" do
        service = described_class.new(provider)
        expect(service.chunk_text("   ")).to eq([])
      end
    end

    context "with short text that fits in one chunk" do
      it "returns single chunk with position 'only'" do
        service = described_class.new(provider)
        text = "This is a short text."

        result = service.chunk_text(text)

        expect(result.length).to eq(1)
        expect(result.first[:content]).to eq(text)
        expect(result.first[:position]).to eq("only")
        expect(result.first[:token_count]).to be > 0
      end
    end

    context "with text requiring multiple chunks" do
      it "splits text into overlapping chunks" do
        provider.chunk_size = 50    # tokens (~150 chars)
        provider.chunk_overlap = 10 # 10% = 5 tokens (~15 chars)
        service = described_class.new(provider)

        # Create text that needs multiple chunks (~400 chars > 150 char target)
        text = "First sentence here with more words to make it longer. " \
               "Second sentence continues with additional content. " \
               "Third sentence follows right behind it now. " \
               "Fourth sentence appears with even more text. " \
               "Fifth sentence comes next and keeps going. " \
               "Sixth sentence ends it all finally here. " \
               "Seventh sentence for good measure."

        result = service.chunk_text(text)

        expect(result.length).to be > 1
        expect(result.first[:position]).to eq("start")
        expect(result.last[:position]).to eq("end")
      end

      it "marks middle chunks as 'middle'" do
        provider.chunk_size = 30    # tokens (~90 chars)
        provider.chunk_overlap = 10
        service = described_class.new(provider)

        # Create text that needs at least 3 chunks
        text = "A" * 300

        result = service.chunk_text(text)

        expect(result.length).to be >= 3
        expect(result.first[:position]).to eq("start")
        expect(result[1][:position]).to eq("middle")
        expect(result.last[:position]).to eq("end")
      end

      it "includes overlap between chunks" do
        provider.chunk_size = 50
        provider.chunk_overlap = 20 # 20% = 10 tokens
        service = described_class.new(provider)

        text = "Word " * 100

        result = service.chunk_text(text)

        # With overlap, chunks should share some content
        expect(result.length).to be > 1

        # Verify there's some overlap
        # The end of chunk 1 should appear at the start of chunk 2
        first_chunk_end = result[0][:content].split.last(5).join(" ")
        second_chunk_start = result[1][:content].split.first(10).join(" ")

        expect(second_chunk_start).to include(first_chunk_end.split.last)
      end
    end

    context "sentence boundary handling" do
      it "tries to break at sentence boundaries" do
        provider.chunk_size = 30 # Small chunk to force breaks
        provider.chunk_overlap = 10
        service = described_class.new(provider)

        text = "First sentence ends here. Second sentence begins now. Third sentence follows."

        result = service.chunk_text(text)

        # At least one chunk should end with a sentence ending
        has_sentence_break = result.any? { |chunk| chunk[:content].match?(/[.!?]$/) }
        expect(has_sentence_break).to be true
      end

      it "falls back to word boundary when sentence break is too early in chunk" do
        # Create scenario where sentence boundary exists but is too early
        # (less than 50% into the chunk), forcing fallback to word boundary
        provider.chunk_size = 100 # ~300 chars target
        provider.chunk_overlap = 0
        service = described_class.new(provider)

        # First few chars have sentence end, rest is continuous without sentences
        # "X. " at position 0-2, then ~297 chars of continuous text
        # Search region is last 20% = ~60 chars
        # Sentence boundary at position ~2 is less than 50% (150 chars), so rejected
        text = "X. " + ("abcdefghij" * 40)

        result = service.chunk_text(text)

        # Should still produce chunks using word boundary fallback
        expect(result.length).to be > 1
      end
    end

    context "token counting" do
      it "estimates token count based on character length" do
        service = described_class.new(provider)
        text = "A" * 300 # 300 chars = ~100 tokens at 3 chars/token

        result = service.chunk_text(text)

        expect(result.first[:token_count]).to eq(100)
      end
    end

    context "whitespace normalization" do
      it "normalizes multiple whitespace to single space" do
        service = described_class.new(provider)
        text = "Words   with    multiple   spaces."

        result = service.chunk_text(text)

        expect(result.first[:content]).to eq("Words with multiple spaces.")
      end

      it "trims leading and trailing whitespace" do
        service = described_class.new(provider)
        text = "   Trimmed text   "

        result = service.chunk_text(text)

        expect(result.first[:content]).to eq("Trimmed text")
      end
    end

    context "word boundary handling" do
      it "attempts to break at spaces between words" do
        provider.chunk_size = 20 # Small to test word boundaries
        provider.chunk_overlap = 10
        service = described_class.new(provider)

        text = "The quick brown fox jumps over the lazy dog and runs away fast"

        result = service.chunk_text(text)

        # With reasonable-sized words, chunks should end/start at spaces
        expect(result.length).to be > 1

        # Each chunk should be non-empty and contain complete words
        result.each do |chunk|
          expect(chunk[:content]).to be_present
        end
      end

      it "handles text where break position lands on a space" do
        provider.chunk_size = 10 # ~30 chars
        provider.chunk_overlap = 0
        service = described_class.new(provider)

        # Text with words that make it easy to land on spaces
        # "ab ab ab ab ab ab ab ab ab ab ab ab ab ab ab ab ab ab ab ab"
        # At 30 chars (10 tokens * 3), we should be at or near a space
        text = ([ "ab" ] * 30).join(" ")

        result = service.chunk_text(text)

        expect(result.length).to be > 1
        result.each do |chunk|
          expect(chunk[:content]).to be_present
        end
      end

      it "handles end of text boundary" do
        provider.chunk_size = 50
        provider.chunk_overlap = 0
        service = described_class.new(provider)

        # Text that's just over one chunk, second chunk will hit end
        text = "a" * 200

        result = service.chunk_text(text)

        expect(result.length).to be >= 2
        expect(result.last[:position]).to eq("end")
      end
    end

    context "edge cases for word boundary detection" do
      it "returns position when at end of text" do
        provider.chunk_size = 10
        provider.chunk_overlap = 0
        service = described_class.new(provider)

        text = "short"
        # Directly test end-of-text boundary
        result = service.send(:find_word_boundary, text, text.length)
        expect(result).to eq(text.length)
      end

      it "returns position when exactly on a space" do
        provider.chunk_size = 10
        provider.chunk_overlap = 0
        service = described_class.new(provider)

        text = "hello world"
        space_pos = 5 # The space between hello and world
        result = service.send(:find_word_boundary, text, space_pos)
        expect(result).to eq(space_pos)
      end
    end

    context "edge cases for sentence boundary detection" do
      it "uses sentence boundary when found in search region" do
        provider.chunk_size = 100
        provider.chunk_overlap = 0
        service = described_class.new(provider)

        # Text with sentence ending in the search region (last 20%)
        # search_start = end_pos - (target_chars * 0.2)
        text = ("x" * 280) + ". " + ("y" * 18)
        start_pos = 0
        end_pos = 300
        target_chars = 300
        # search_start = 300 - 60 = 240
        # search_region = text[240..299] contains ". " at position ~40

        result = service.send(:find_break_point, text, start_pos, end_pos, target_chars)

        # Should break at the sentence boundary
        expect(result).to be_between(280, 285)
      end
    end
  end
end
