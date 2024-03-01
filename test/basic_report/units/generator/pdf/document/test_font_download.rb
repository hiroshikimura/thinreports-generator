# frozen_string_literal: true

require 'test_helper'

class Thinreports::BasicReport::Generator::PDF::TestFontDownload < Minitest::Test
  include Thinreports::BasicReport::TestHelper

  def setup
    # Reset font settings
    Thinreports.configure do |c|
      c.tempdir = 'test-fonts'
      c.fontset = [{
        font_uri: 'https://moji.or.jp/wp-content/ipafont/IPAfont/IPAfont00303.zip',
        fonts: [
          { font_name: 'IPAGothic', file_name: 'ipag.ttf' },
          { font_name: 'IPAPGothic', file_name: 'ipagp.ttf' },
          { font_name: 'IPAMincho', file_name: 'ipam.ttf' },
          { font_name: 'IPAPMincho', file_name: 'ipamp.ttf' },
        ]
      }]
    end
  end

  def teardown
    Thinreports.configure do |c|
      c.tempdir = nil
      c.fontset = nil
    end
  end

  def test_download_setup_fonts
    pdf = document.pdf
    Thinreports::BasicReport::Generator::PDF::Font::BUILTIN_FONTS.map do |name, path|
      expected_font = {
        normal: Thinreports.root.join('test-fonts', File.basename(path)).to_s,
        bold: Thinreports.root.join('test-fonts', File.basename(path)).to_s,
        italic: Thinreports.root.join('test-fonts', File.basename(path)).to_s,
        bold_italic: Thinreports.root.join('test-fonts', File.basename(path)).to_s
      }
      assert_equal expected_font, pdf.font_families[name]
    end
  end

  def document
    Thinreports::BasicReport::Generator::PDF::Document.new
  end
  alias_method :create_document, :document
end
