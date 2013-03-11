class ProjectsController < ApplicationController
  before_filter :authorize

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
