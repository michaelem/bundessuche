# frozen_string_literal: true

require 'test_helper'

class BundesarchivSaxHandlerTest < ActiveSupport::TestCase
  test 'skips archdesc with type other than inventory' do
    xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <ead>
        <archdesc type="other">
          <c level="file" id="should-be-skipped">
            <did>
              <unittitle>Should not be imported</unittitle>
            </did>
          </c>
        </archdesc>
      </ead>
    XML

    handler = BundesarchivSaxHandler.new({})
    Nokogiri::XML::SAX::Parser.new(handler).parse(xml)

    assert_equal 0, handler.total_count
    assert_equal 0, ArchiveFile.count
  end
end
