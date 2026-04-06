  # This file should ensure the existence of records required to run the application in every environment (production,
  # development, test). The code here should be idempotent so that it can be executed at any point in every environment.
  # The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
  #
  # Example:
  #
  #   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
  #     MovieGenre.find_or_create_by!(name: genre_name)
  #   end
  Person.find_or_create_by!(name: "Bob") do |p|
    p.email = "bob@email.com"
    p.phone = "0401"
    p.present = false
  end
  Person.find_or_create_by!(name: "Jill") do |p|
    p.email = "jill@email.com"
    p.phone = "0405"
    p.present = false
  end

  # User accounts (development/test credentials - change in production)
  User.find_or_create_by!(username: "buss") do |u|
    u.password = "buss"
    u.password_confirmation = "buss"
    u.role = :basic
  end

  User.find_or_create_by!(username: "board") do |u|
    u.password = "board"
    u.password_confirmation = "board"
    u.role = :admin
  end
