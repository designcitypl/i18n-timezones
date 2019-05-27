namespace :i18n_timezones do
  require 'active_support/all'

  desc 'Lookup for missing translations of time zones.' \
       'Usage example: `$ rake i18n_timezones:lookup_missing_translations`'
  task lookup_missing_translations: :i18n_setup do
    supported_locales = I18n.available_locales
    puts "looking for locales: #{supported_locales.join ', '}"
    ActiveSupport::TimeZone.all.each do |zone|
      supported_locales.each do |locale|
        I18n.locale = locale
        I18n.t(zone.name, scope: :timezones, raise: true, separator: '\001')
      rescue I18n::MissingTranslationData => e
        puts translation_missing_error(e, zone)

        puts "#{e.message} (\"#{zone.name}\": \"\" # " \
             "#{zone.tzinfo.identifier}; GMT#{zone.formatted_offset})"
      end
    end
  end

  desc 'Setup I18n for this gem'
  task :i18n_setup do
    require 'i18n'

    Dir.chdir(File.expand_path('../../../rails/locale', __dir__)) do
      I18n.enforce_available_locales = false
      config = I18n.config
      config.available_locales = Dir['*.yml'].map { |x| x[/.+(?=.yml)/] } - %w[en]
      config.load_path = Dir['*.yml'].map { |x| File.join(Dir.pwd, x) }
    end
  end

  desc 'Creates .yml file for given locale with missing keys for timezones.' \
       'Uses exisitng translations included in given locale (if exists).' \
       'locale: locale; description: adds timezone.identifier if true, nil' \
       'todos: adds TODOs with translation missing comment' \
       'Usage example: `$ rake i18n_timezones:prepare_yaml_file[pl, true, nil]`'
  task :prepare_yaml_file, [:locale, :description, :todos] do |_, args|
    locale = I18n.locale = args[:locale]
    header = "# Generated i18n-timezones translation file for '#{locale}'.\n"
    output = "#{header}\n#{locale}:\n  timezones:\n"
    output.concat(dictionary_rows(args[:description], args[:todos]))

    # Path to app config files
    path = File.join(Rails.root, 'config', 'locales', 'timezones')
    FileUtils.mkdir_p(path)
    filename = File.join(path, "timezones.#{locale}.yml")
    File.open(filename, 'w+') { |f| f.write(output) }
    puts "\nWritten Time Zones for '#{locale}' into: #{filename}\n"
  end
  task prepare_yaml_file: :i18n_setup

  desc 'Creates .yml file for given locale with missing keys for timezones.' \
       'Uses exisitng translations included in given locale (if exists).' \
       'locale: locale; description: adds timezone.identifier if true, nil' \
       'todos: adds TODOs with translation missing comment' \
       'Usage example: `$ rake i18n_timezones:prepare_yaml_file[pl, true, nil]`'
  task :prepare_dev_yaml_file, [:locale, :description, :todos] do |_, args|
    locale = I18n.locale = args[:locale]
    output = "#{locale}:\n  timezones:\n"
    output.concat(dictionary_rows(args[:description], args[:todos]))

    # Path to gem
    path = File.expand_path('../../../', __dir__)
    filename = File.join(path, 'rails', 'locale', "#{locale}.yml")
    File.open(filename, 'w+') { |f| f.write(output) }
    puts "\nWritten Time Zones for '#{locale}' into: #{filename}\n"
  end
  task prepare_dev_yaml_file: :i18n_setup

  #
  # desc 'Show timezones in alphabetical order'
  # task :show_timezones_alphabetical do
  #   ActiveSupport::TimeZone.all.map(&:name).sort.each do |zone|
  #     puts zone
  #   end
  # end

  def dictionary_rows(description = nil, todos = nil)
    output = ''
    ActiveSupport::TimeZone.all.each do |zone|
      output.concat("#{add_row(zone, description)}\n")
    rescue I18n::MissingTranslationData => e
      output.concat("#{translation_missing_error(e, zone, todos)}\n")
    end
    output
  end

  def add_row(zone, description = nil)
    t = I18n.t(zone.name, scope: :timezones, raise: true, separator: '\001')
    row = "    \"#{zone.name}\": \"#{t}\""
    return unless description == 'true'

    row.concat(" # #{zone.tzinfo.identifier} GMT#{zone.formatted_offset}")
  end

  def translation_missing_error(error, zone, todos = nil)
    row = "    # \"#{zone.name}\": \"\" # " \
          "#{zone.tzinfo.identifier} GMT#{zone.formatted_offset}"
    row.prepend("    # TODO: #{error.message};\n") if todos == 'true'
  end
end
