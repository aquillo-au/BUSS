require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  fixtures :users

  setup do
    @user = users(:buss_user)
    post login_path, params: { username: @user.username, password: "buss" }
  end

  test "person sign-ins shows average attendance badge" do
    person = Person.create!(name: "Report Person")

    week_one = Time.zone.local(2026, 1, 5, 9, 0, 0)
    week_two = Time.zone.local(2026, 1, 12, 9, 0, 0)

    SignIn.create!(person: person, arrived_at: week_one, left_at: week_one + 45.minutes, is_haven_checkin: false)
    SignIn.create!(person: person, arrived_at: week_two, left_at: week_two + 30.minutes, is_haven_checkin: false)
    SignIn.create!(person: person, arrived_at: week_two + 1.day, left_at: week_two + 1.day + 40.minutes, is_haven_checkin: false)
    SignIn.create!(person: person, arrived_at: week_two + 2.days, left_at: week_two + 2.days + 50.minutes, is_haven_checkin: false)

    get reports_person_sign_ins_path(person, period: "year")

    assert_response :success
    assert_includes response.body, "Avg attendance:"
    assert_includes response.body, "2.0 visits/week"
  end

  test "category averages shows attendance metric" do
    person1 = Person.create!(name: "Category Person 1")
    person2 = Person.create!(name: "Category Person 2")
    date = Time.zone.local(2026, 1, 7, 9, 0, 0)

    SignIn.create!(person: person1, arrived_at: date, left_at: date + 40.minutes, is_haven_checkin: false)
    SignIn.create!(person: person2, arrived_at: date + 30.minutes, left_at: date + 70.minutes, is_haven_checkin: false)

    get reports_category_averages_path(date: date.to_date.iso8601)

    assert_response :success
    assert_includes response.body, "Average attendance:"
    assert_includes response.body, "2 people"
  end
end
