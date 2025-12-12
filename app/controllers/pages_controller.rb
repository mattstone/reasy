# frozen_string_literal: true

class PagesController < ApplicationController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def home
  end

  def about
  end

  def how_it_works
  end

  def pricing
  end

  def contact
  end

  def index1
  end

  def index2
  end

  def index3
  end

  def index4
  end

  def index5
  end
end
