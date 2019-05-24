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
      # config.default_locale = config.available_locales.first
      config.load_path = Dir['*.yml'].map { |x| File.join(Dir.pwd, x) }
    end
  end

  desc 'Puts content for localization .yml file for given locale with #TODOs ' \
       'if translation missing. Uses translations included in existing file.' \
       'Usage example: `$ rake i18n_timezones:prepare_yaml[pl]`'
  task :prepare_yaml, [:locale, :description] do |_, args|
    I18n.locale = args[:locale]
    # I18n.enforce_available_locales = false
    # puts I18n.available_locales
    puts "#{I18n.locale}:", '  timezones:'
    ActiveSupport::TimeZone.all.each do |zone|
      t = I18n.t(zone.name, scope: :timezones, raise: true, separator: '\001')
      row = "    \"#{zone.name}\": \"#{t}\""
      if args[:description] == true
        row.concat(" # #{zone.tzinfo.identifier} GMT#{zone.formatted_offset}")
      end
      puts row
    rescue I18n::MissingTranslationData => e
      puts "    #TODO: #{e.message}; \"#{zone.name}\": \"\" # " \
           "#{zone.tzinfo.identifier} GMT#{zone.formatted_offset}"
    end
  end
  task prepare_yaml: :i18n_setup

  desc 'Show timezones in alphabetical order'
  task :show_timezones_alphabetical do
    ActiveSupport::TimeZone.all.map(&:name).sort.each do |zone|
      puts zone
    end
  end
end
