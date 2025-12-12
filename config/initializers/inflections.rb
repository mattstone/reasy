# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

ActiveSupport::Inflector.inflections(:en) do |inflect|
  # Fix "loves" singularization (Rails incorrectly converts to "lofe")
  inflect.irregular "love", "loves"

  # AI acronym should stay uppercase
  inflect.acronym "AI"

  # KYC acronym
  inflect.acronym "KYC"

  # ABN, ACN, TFN
  inflect.acronym "ABN"
  inflect.acronym "ACN"
  inflect.acronym "TFN"

  # SMSF
  inflect.acronym "SMSF"

  # API
  inflect.acronym "API"
end
