# frozen_string_literal: true
require 'fileutils'
require 'zip'
require 'net/http'

module Thinreports
  module BasicReport
    module Generator
      class PDF
        module Font
          FONT_STORE = Thinreports.root.join('fonts')

          BUILTIN_FONTS = {
            'IPAMincho'  => FONT_STORE.join('ipam.ttf').to_s,
            'IPAPMincho' => FONT_STORE.join('ipamp.ttf').to_s,
            'IPAGothic'  => FONT_STORE.join('ipag.ttf').to_s,
            'IPAPGothic' => FONT_STORE.join('ipagp.ttf').to_s
          }.freeze

          DEFAULT_FALLBACK_FONTS = %w[IPAMincho].freeze

          PRAWN_BUINTIN_FONT_ALIASES = {
            'Courier New' => 'Courier',
            'Times New Roman' => 'Times-Roman'
          }.freeze

          def setup_fonts
            # Install built-in fonts.
            setup_default_fonts.each do |font_name, font_path|
              install_font(font_name, font_path)
            end

            # Create aliases from the font list provided by Prawn.
            PRAWN_BUINTIN_FONT_ALIASES.each do |alias_name, name|
              pdf.font_families[alias_name] = pdf.font_families[name]
            end

            # Setup custom fallback fonts
            fallback_fonts = Thinreports.config.fallback_fonts.uniq
            fallback_fonts.map!.with_index do |font, i|
              if pdf.font_families.key?(font)
                font
              else
                install_font "Custom-fallback-font#{i}", font
              end
            end

            # Set fallback fonts
            pdf.fallback_fonts(fallback_fonts + DEFAULT_FALLBACK_FONTS)
          end

          # @param [String] name
          # @param [String] file
          # @return [String] installed font name
          def install_font(name, file)
            raise Errors::FontFileNotFound unless File.exist?(file)

            pdf.font_families[name] = {
              normal: file,
              bold: file,
              italic: file,
              bold_italic: file
            }
            name
          end

          # @return [String]
          def default_family
            'Helvetica'
          end

          # @param [String] family
          # @return [String]
          def default_family_if_missing(family)
            pdf.font_families.key?(family) ? family : default_family
          end

          # @param [String] font_name
          # @param [:bold, :italic] font_style
          # @return [Boolean]
          def font_has_style?(font_name, font_style)
            font = pdf.font_families[font_name]

            return false unless font
            return false unless font.key?(font_style)

            font[font_style] != font[:normal]
          end

          def setup_default_fonts
            @setup_default_fonts ||= build_fonts_config
          end

          def build_fonts_config
            current_config.each_with_object({}) do |entry, hash|
              hash.merge! build_font_config(entry)
            end.then do |h|
              BUILTIN_FONTS.merge(h)
            end
          end

          def build_font_config(entry)
            h = index_by(entry[:fonts]){ |e| File.basename(e[:file_name]) }
            download_fonts(entry[:font_uri]).
              select { |e| h.key?(File.basename(e)) }.
              each_with_object({}) do |font_path, hash|
                hash[(h[File.basename(font_path)] || {})[:font_name] ] = font_path
              end
          end

          def index_by(array)
            array.each_with_object({}) do |e, h|
              h[ yield(e)] = e
            end
          end

          def download_fonts(archive_file)
            uri = URI.parse(archive_file)
            tempdir = current_temp_dir
            FileUtils.mkdir_p tempdir
            dst = [tempdir, File.basename(uri.path)].join(File::SEPARATOR)
            progressive_download(uri, dst)

            # extract & configure
            Zip::File.open(dst) do |zip|
              zip.map do |entry|
                filename = File.basename(entry.name)
                tmpname = [tempdir, filename].join(File::SEPARATOR)
                zip.extract(entry, tmpname) { true }
                tmpname
              end
            end.tap { FileUtils.rm_rf dst }
          end

          def progressive_download(uri, dest)
            File.open(dest, "wb") do |file|
              http = Net::HTTP.new(uri.hostname, uri.port)
              http.use_ssl = true
              http.start
              http.get("#{uri.path}?#{uri.query}") do |body_segment|
                file.write body_segment
              end
              http.finish
            end
          end

          def download(uri, dest)
            File.open(dest, 'wb') { |f| f.write Net::HTTP.get(uri) }
          end

          def current_config
            Thinreports.config.fontset.then { |e| e.size > 0 ? e : default_font_config }
          end

          def current_temp_dir
            @current_temp_dir ||= -> do
              rooter = Object.const_get('Rails') rescue Thinreports
              rooter.root.join((Thinreports.config.tempdir || 'fonts').gsub(/#{File::SEPARATOR}{0,}$/, ''))
            end.call
          end

          def default_font_config
            [{
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
      end
    end
  end
end
