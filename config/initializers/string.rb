class String
  # Non breaking spaces: \0xC2\0xA0, \0xA0
  # Read more: http://en.wikipedia.org/wiki/Non-breaking_space
  NON_BREAKING_SPACES_ISO = ["\xC2\xA0", "\xA0"].map do |nbsp|
    nbsp.force_encoding('iso-8859-1')
  end
  NON_BREAKING_SPACES = NON_BREAKING_SPACES_ISO.map { |nbsp| nbsp.encode('utf-8') }

  NON_BREAKING_SPACES_ISO_RE = /\s+|#{NON_BREAKING_SPACES_ISO.join('|')}/
  NON_BREAKING_SPACES_RE = /\s+|#{NON_BREAKING_SPACES.join('|')}/

  def clean
    self.gsub(NON_BREAKING_SPACES_RE, ' ').strip
  rescue ArgumentError => exc
    self.force_encoding('iso-8859-1')
        .gsub(NON_BREAKING_SPACES_ISO_RE, ' ')
        .strip
        .encode('utf-8')
  end
  def symbolize
    self.clean.parameterize.gsub('-','_').to_sym
  end
  def no_accents
    I18n.transliterate(self)
  end
end
