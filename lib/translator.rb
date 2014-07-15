require 'translator/engine' if defined?(Rails) && Rails::VERSION::STRING.to_f >= 3.1

module Translator
  class << self
    attr_accessor :framework_keys, :locales, :locales_path_hash
    attr_reader :simple_backend
    attr_writer :layout_name
  end

  @framework_keys = ["date.formats.default", "date.formats.short", "date.formats.long",
                     "time.formats.default", "time.formats.short", "time.formats.long", "time.am", "time.pm",
                     "support.array.words_connector", "support.array.two_words_connector", "support.array.last_word_connector",
                     "errors.format", "errors.messages.inclusion", "errors.messages.exclusion", "errors.messages.invalid",
                     "errors.messages.confirmation", "errors.messages.accepted", "errors.messages.empty",
                     "errors.messages.blank", "errors.messages.too_long", "errors.messages.too_short", "errors.messages.wrong_length",
                     "errors.messages.not_a_number", "errors.messages.not_an_integer", "errors.messages.greater_than",
                     "errors.messages.greater_than_or_equal_to", "errors.messages.equal_to", "errors.messages.less_than",
                     "errors.messages.less_than_or_equal_to", "errors.messages.odd", "errors.messages.even", "errors.required", "errors.blank",
                     "number.format.separator", "number.format.delimiter", "number.currency.format.format", "number.currency.format.unit",
                     "number.currency.format.separator", "number.currency.format.delimiter", "number.percentage.format.delimiter",
                     "number.precision.format.delimiter", "number.human.format.delimiter", "number.human.storage_units.format",
                     "number.human.storage_units.units.byte.one", "number.human.storage_units.units.byte.other",
                     "number.human.storage_units.units.kb", "number.human.storage_units.units.mb", "number.human.storage_units.units.gb",
                     "number.human.storage_units.units.tb", "number.human.decimal_units.format", "number.human.decimal_units.units.unit",
                     "number.human.decimal_units.units.thousand", "number.human.decimal_units.units.million",
                     "number.human.decimal_units.units.billion", "number.human.decimal_units.units.trillion",
                     "number.human.decimal_units.units.quadrillion", "datetime.distance_in_words.half_a_minute",
                     "datetime.distance_in_words.less_than_x_seconds.one", "datetime.distance_in_words.less_than_x_seconds.other",
                     "datetime.distance_in_words.x_seconds.one", "datetime.distance_in_words.x_seconds.other",
                     "datetime.distance_in_words.less_than_x_minutes.one", "datetime.distance_in_words.less_than_x_minutes.other",
                     "datetime.distance_in_words.x_minutes.one", "datetime.distance_in_words.x_minutes.other",
                     "datetime.distance_in_words.about_x_hours.one", "datetime.distance_in_words.about_x_hours.other",
                     "datetime.distance_in_words.x_days.one", "datetime.distance_in_words.x_days.other",
                     "datetime.distance_in_words.about_x_months.one", "datetime.distance_in_words.about_x_months.other",
                     "datetime.distance_in_words.x_months.one", "datetime.distance_in_words.x_months.other",
                     "datetime.distance_in_words.about_x_years.one", "datetime.distance_in_words.about_x_years.other",
                     "datetime.distance_in_words.over_x_years.one", "datetime.distance_in_words.over_x_years.other",
                     "datetime.distance_in_words.almost_x_years.one", "datetime.distance_in_words.almost_x_years.other",
                     "datetime.prompts.year", "datetime.prompts.month", "datetime.prompts.day", "datetime.prompts.hour",
                     "datetime.prompts.minute", "datetime.prompts.second", "helpers.select.prompt", "helpers.submit.create",
                     "helpers.submit.update", "helpers.submit.submit"]

  def self.setup_backend(simple_backend)
    @simple_backend = simple_backend
  end

  def self.locales
    @locales
  end

  def self.keys_for_strings(options = {})
    @simple_backend.available_locales

    flat_translations = {}
    flatten_keys nil, @simple_backend.instance_variable_get("@translations")[:en], flat_translations
    flat_translations = flat_translations.delete_if {|k,v| !v.is_a?(String) }

    keys = flat_translations.keys

    if options[:filter]
      keys = keys.select {|k| k[0, options[:filter].size] == options[:filter]}
    end

    case options[:group].to_s
    when "framework"
      keys.select! {|k| @framework_keys.include?(k) }
    when "application"
      keys -= @framework_keys
    end

    keys || []
  end

  def self.layout_name
    @layout_name || "translator"
  end

  def self.create_hash(key, value)
    {key => value}
  end

  # give reversed array
  def self.nest_hash_from_array(array, value)
    while !array.empty?
      if array.length == 1
        some_hash = create_hash(array.pop, value)
      else
        some_hash = create_hash(array.pop, nest_hash_from_array(array, value))
      end
    end
    return some_hash
  end

  def self.deep_merge(first, second)
    merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    first.merge!(second, &merger)
  end

  def self.path_to_locale(locale)
    File.join(Rails.root, 'config', 'locales', @locales_path_hash[locale])
  end

  private

  def self.flatten_keys(current_key, hash, dest_hash)
    hash.each do |key, value|
      full_key = [current_key, key].compact.join('.')
      if value.kind_of?(Hash)
        flatten_keys full_key, value, dest_hash
      else
        dest_hash[full_key] = value
      end
    end
    hash
  end
end
