# frozen_string_literal: true

module CitationHelper
  # SVG icon for external link (used in citation links)
  CITATION_ICON_SVG = <<~SVG.squish.freeze
    <svg class="citation-icon" viewBox="0 0 16 16" width="12" height="12">
      <path fill="currentColor" d="M4.5 3.5a1 1 0 0 0-1 1v8a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1v-3a.5.5 0 0 1 1 0v3a2 2 0 0 1-2 2h-8a2 2 0 0 1-2-2v-8a2 2 0 0 1 2-2h3a.5.5 0 0 1 0 1h-3z"/>
      <path fill="currentColor" d="M9 1.5a.5.5 0 0 1 .5-.5h5a.5.5 0 0 1 .5.5v5a.5.5 0 0 1-1 0V2.707l-5.146 5.147a.5.5 0 0 1-.708-.708L13.293 2H9.5a.5.5 0 0 1-.5-.5z"/>
    </svg>
  SVG

  # Generates JavaScript code for converting inline citations to links
  # Pass sources as an array of hashes with :number, :type, :id, :title keys
  def citation_converter_js(sources)
    return "" if sources.blank?

    sources_json = sources.to_json

    <<~JS.html_safe
      (function() {
        window.CitationHelper = window.CitationHelper || {};

        window.CitationHelper.sources = #{sources_json};

        window.CitationHelper.escapeHtml = function(text) {
          var div = document.createElement('div');
          div.textContent = text;
          return div.innerHTML;
        };

        window.CitationHelper.convertInlineCitations = function(html) {
          var sources = window.CitationHelper.sources;
          if (!sources || sources.length === 0) return html;

          // Build source map
          var sourceMap = {};
          sources.forEach(function(source, index) {
            var num = source.number || (index + 1);
            sourceMap[num] = source;
          });

          // Replace [1], [2], etc. with clickable links
          return html.replace(/\\[(\\d+)\\]/g, function(match, num) {
            var source = sourceMap[parseInt(num, 10)];
            if (!source) return match;

            var path = source.type === 'Article' ? '/articles/' : '/questions/';
            var url = path + (source.slug || source.id);
            var title = window.CitationHelper.escapeHtml(source.title || 'Source ' + num);

            return '<a href="' + url + '" class="citation-link" title="' + title + '" target="_blank">' +
              '<sup>[' + num + ']</sup>' +
              '#{CITATION_ICON_SVG.gsub("'", "\\\\'")}' +
              '</a>';
          });
        };

        window.CitationHelper.renderSourcesList = function(sources) {
          if (!sources || sources.length === 0) return '';

          var html = '<div class="citation-sources">';
          html += '<div class="citation-sources-label">Sources</div>';
          html += '<div class="citation-source-list">';

          sources.forEach(function(source, index) {
            var num = source.number || (index + 1);
            var path = source.type === 'Article' ? '/articles/' : '/questions/';
            var slug = source.slug || source.id;
            html += '<div class="citation-source-item">';
            html += '<span class="citation-source-number">[' + num + ']</span>';
            html += '<span class="citation-source-type">' + window.CitationHelper.escapeHtml(source.type) + '</span>';
            html += '<a href="' + path + slug + '" class="citation-source-link" target="_blank">' +
                    window.CitationHelper.escapeHtml(source.title) + '</a>';
            html += '</div>';
          });

          html += '</div></div>';
          return html;
        };
      })();
    JS
  end
end
