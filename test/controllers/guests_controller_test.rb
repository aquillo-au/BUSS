require "test_helper"

class GuestsControllerTest < ActionDispatch::IntegrationTest
  fixtures :users

  setup do
    @user = users(:board_user)
    post login_path, params: { username: @user.username, password: "board" }
  end

  test "history includes average attendance series in attendee chart" do
    person1 = Person.create!(name: "Chart Person 1")
    person2 = Person.create!(name: "Chart Person 2")
    person3 = Person.create!(name: "Chart Person 3")

    monday = Time.zone.local(2026, 1, 5, 9, 0, 0)
    tuesday = Time.zone.local(2026, 1, 6, 10, 0, 0)

    SignIn.create!(person: person1, arrived_at: monday, left_at: monday + 60.minutes, is_haven_checkin: false)
    SignIn.create!(person: person2, arrived_at: monday + 1.hour, left_at: monday + 2.hours, is_haven_checkin: false)
    SignIn.create!(person: person3, arrived_at: tuesday, left_at: tuesday + 30.minutes, is_haven_checkin: false)

    get history_guests_path(period: "year")

    assert_response :success
    assert_includes response.body, "Average Attendance"
  end
end
