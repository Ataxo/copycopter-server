require 'csv'
require 'pp'
class ProjectsController < ApplicationController
  before_filter :authorize

  CSV_SETTINGS = { :col_sep => ',', :row_sep => ?\n, :quote_char => '"', :force_quotes => true }

  def index
    @projects = Project.active
  end

  def show
    @project = Project.find(params[:id])
    @locale = @project.locale(params[:locale_id])

    if stale? :etag => @project.etag
      @localizations = @project.localizations.in_locale_with_blurb(@locale)
    end
  end

  def csv

    @project = Project.find(params[:id])
    out = {}
    locales = @project.locales.collect{|l| l.key}
    @project.blurbs.to_hash("published_content")[:data].each do |key, translation|
      ks = key.split(".")
      lang = ks[0]
      name = ks[1..-1].join(".")
      out[name] ||= {}
      out[name][lang] = translation
    end

    data = CSV.generate_line(["key"]+locales, CSV_SETTINGS)

    out.each do |key, values|
      data += CSV.generate_line([key]+locales.collect{|l| values.has_key?(l) ? values[l] : "" }, CSV_SETTINGS)
    end

    send_data data,
      :type => 'text/csv; charset=utf-8; header=present',
      :disposition => "attachment; filename=#{@project.name}.csv",
      :status => 200
  end

  def import_csv
    @project = Project.find(params[:id])
    if params[:csv]
      begin
        csv = CSV.parse(params[:csv].read, CSV_SETTINGS)

        locales = csv[0][1..-1]

        import_data = {}
        update_data = {}
        csv[1..-1].each do |line|
          key = line[0]
          row_data = line[1..-1]
          locales.each_with_index do |locale, index|
            import_data["#{locale}.#{key}"] = row_data[index]
            update_data[key] ||= {}
            update_data[key][locale] = row_data[index]
          end
        end
        @project.create_defaults import_data

        project_locales = @project.locales.inject({}){|o, i| o[i.id] = i; o}

        message = 0
        update_data.each do |key, locales|
          if blurbs = @project.blurbs.where(:key => key).includes(:localizations)
            blurbs.each do |blurb|
              blurb.localizations.each do |localization|
                loc = project_locales[localization.locale_id].key
                if locales.has_key?(loc)
                  localization.draft_content = locales[loc]
                  localization.published_content = locales[loc]
                  localization.save
                  message += 1
                end
              end
            end
          end
        end
        flash[:notice] = message
        @project.update_caches

      rescue Exception => e
        flash[:failure] = "#{e.message}<br /><small>#{e.backtrace[0..10].join("<br />")}</small>".html_safe
      end
    end
  end

  def empty_blurbs
    @project = Project.find(params[:id])
    locales = @project.locales.collect{|l| l.id}.sort
    blurbs = @project.blurbs.includes(:localizations).select do |b|
      b.localizations.all?{|l| l.draft_content == "" && l.published_content == "" } &&
      b.localizations.collect{|l| l.locale_id}.sort == locales
    end.collect{|b| b.id}

    Blurb.disable_update_of_cache
    Blurb.destroy(blurbs)
    Blurb.enable_update_of_cache

    flash[:notice] = "#{blurbs.size} blurbs were successfully deleted"

    @project.update_caches

    redirect_to @project
  end

end
