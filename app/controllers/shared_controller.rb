class SharedController < ApplicationController

  def is_alive
    begin
      Project.all
      render :json => { status: "ok", message: "Oh yeah Baby! Copycopter is alive :-)"}
    rescue Exception => e
      render :json => { status: "error", message: "NOT ALIVE! #{e.message}"}
    end
  end
end
