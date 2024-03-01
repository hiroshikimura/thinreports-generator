# frozen_string_literal: true

module Thinreports
  # @yield [config]
  # @yieldparam [Thinreports::Configuration] config
  def self.configure(&block)
    block.call(config)
  end

  # @return [Thinreports::Configuration]
  def self.config
    @config ||= Thinreports::Configuration.new
  end

  class Configuration
    def initialize
      @fallback_fonts = []
    end

    # @return [Array<String>]
    # @example
    #   config.fallback_fonts # => ['Times New Roman', '/path/to/font.ttf']
    def fallback_fonts
      @fallback_fonts ||= []
    end

    # @param [Array<String>,String] font_names
    # @example
    #   config.fallback_fonts = 'Times New Roman'
    #   config.fallback_fonts = '/path/to/font.ttf'
    #   config.fallback_fonts = ['/path/to/font.ttf', 'IPAGothic']
    def fallback_fonts=(font_names)
      @fallback_fonts = font_names.is_a?(Array) ? font_names : [font_names]
    end

    def tempdir
      @tempdir ||= 'fonts'
    end

    def tempdir=(tempdir)
      @tempdir = tempdir
    end

    def fontset
      @fontset ||= []
    end

    # @param [Array<Hash>]
    # @example
    #   config.fonts = [{
    #     font_uri: 'http://example.com/path/to/font.ttf.zip',
    #     fonts: [
    #       { font_name: 'IPAGothic', file_name: 'ipag.ttf' },
    #       { font_name: 'IPAPGothic', file_name: 'ipagp.ttf' },
    #       { font_name: 'IPAMincho', file_name: 'ipam.ttf' },
    #       { font_name: 'IPAPMincho', file_name: 'ipamp.ttf' },
    #     ]
    #   }]
    def fontset=(font_set)
      @fontset = font_set
    end
  end
end
