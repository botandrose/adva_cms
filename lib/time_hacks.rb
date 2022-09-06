class Time
  # Time.now.to_ordinalized_s :long
  # => "February 28th, 2006 21:10"
  def to_ordinalized_s(format = :default)
    format = DATE_FORMATS[format]
    return to_default_s if format.nil?
    strftime(format.gsub(/%d/, '_%d_')).gsub(/_(\d+)_/) { |s| s.to_i.ordinalize }
  end

  DATE_FORMATS.update \
    :standard  => '%B %d, %Y @ %I:%M %p',
    :stub      => '%B %d',
    :time_only => '%I:%M %p',
    :plain     => '%B %d %I:%M %p',
    :mdy       => '%B %d, %Y',
    :my        => '%B %Y'
end
