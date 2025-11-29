class PagesController < ApplicationController
  allow_unauthenticated_access
  layout "landing", only: [:home]

  def home
  end
end
