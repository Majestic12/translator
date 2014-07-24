module Translator
  class TranslationsController < ApplicationController
    skip_before_filter :authenticate_user!
    skip_before_filter :verify_authenticity_token
    skip_authorization_check

    def index
      section = params[:key].present? && params[:key] + '.'
      params[:group] = "all" unless params["group"]
      @sections = Translator.keys_for_strings(:group => params[:group]).map {|k| k = k.scan(/^[a-zA-Z0-9\-_]*\./)[0]; k ? k.gsub('.', '') : false}.select{|k| k}.uniq.sort
      @groups = ["framework", "application"]
      @keys = Translator.keys_for_strings(:group => params[:group], :filter => section)

      if params[:search]
        @keys = @keys.select {|k|
          Translator.locales.any? {|locale| I18n.translate("#{k}", :locale => locale).to_s.downcase.include?(params[:search].downcase)}
        }
      end

      if params[:translated] == '1'
        @keys = @keys.select {|k|
          Translator.locales.all? {|locale| (begin I18n.backend.translate(locale, "#{k}") rescue nil; end).present? }
        }
      end

      if params[:translated] == '0'
        @keys = @keys.select {|k|
          Translator.locales.any? {|locale| (begin I18n.backend.translate(locale, "#{k}") rescue nil; end).blank? }
        }
      end

      @keys = paginate(@keys)
      render :layout => Translator.layout_name
    end

    def create
      @key_value = params[:value].to_s
      begin
        nests = params[:key].split(/\./)
        nest_value = params[:value]
        yaml_file = nil
        # check first line of hash for locale
        # ensure initializer in main app has correct file path for yaml
        if Translator.locales_path_hash.has_key?(nests[0])
          yaml_file = Translator.path_to_locale(nests[0])
        else
          raise 'ERROR - Locale not editable'
        end

        # in case writing failed
        backup_data = YAML.load_file yaml_file

        nests_reversed = nests.reverse
        ready_hash = Translator.nest_hash_from_array(nests_reversed, nest_value)
        data = YAML.load_file yaml_file
        Translator.deep_merge(data, ready_hash)

        File.open(yaml_file, 'w') do |file|
          data_yaml = data.ya2yaml
          file.puts data_yaml
        end
        @success = "[updated]";
      rescue => e
        puts '**************************************************'
        puts 'Failed to update yaml file - ERROR:'
        puts e
        puts ''
        puts 'Reverting changes...'
        puts '**************************************************'

        File.open(yaml_file, 'w') do |file|
          data_yaml = backup_data.ya2yaml
          file.puts data_yaml
        end
        @success = "[failed]";
      end
    end

    private
    def paginate(collection)
      @page = params[:page].to_i
      @page = 1 if @page == 0
      @total_pages = (collection.count / 50.0).ceil
      collection[(@page-1)*50..@page*50]
    end
  end
end
