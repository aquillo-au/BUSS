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

  test "history program cards show average attendance metric for selected period" do
    person1 = Person.create!(name: "Program Metric Person 1")
    person2 = Person.create!(name: "Program Metric Person 2")
    person3 = Person.create!(name: "Program Metric Person 3")

    week_one = Time.current.beginning_of_year + 7.days
    week_two = week_one + 7.days
    previous_year = Time.current.prev_year.beginning_of_year + 7.days

    SignIn.create!(person: person1, arrived_at: week_one, left_at: week_one + 30.minutes, is_haven_checkin: false)
    SignIn.create!(person: person2, arrived_at: week_one + 1.hour, left_at: week_one + 80.minutes, is_haven_checkin: false)
    SignIn.create!(person: person1, arrived_at: week_two, left_at: week_two + 45.minutes, is_haven_checkin: false)
    SignIn.create!(person: person3, arrived_at: previous_year, left_at: previous_year + 30.minutes, is_haven_checkin: false)

    get history_guests_path(period: "year")

    assert_response :success
    assert_includes response.body, "Avg attendance: 1.5 people"
    date_one = week_one.to_date.strftime("%Y-%m-%d")
    date_two = week_two.to_date.strftime("%Y-%m-%d")
    assert_match(/"Average Attendance","data":\[\["#{date_one}",2(?:\.0)?\],\["#{date_two}",1\.5\]\]/, response.body)
    assert_no_match(/"Average Attendance","data":\[\["#{date_one}",1\.5\],\["#{date_two}",1\.5\]\]/, response.body)
    assert_not_includes response.body, "4 sign-ins"
  end

  test "history lists people alphabetically in admin section" do
    Person.create!(name: "Zulu Admin Person")
    Person.create!(name: "Alpha Admin Person")
    Person.create!(name: "Middle Admin Person")

    get history_guests_path(period: "year")

    assert_response :success
    people_links = css_select("ul.list-group li.list-group-item strong a").map(&:text)

    assert_operator people_links.index("Alpha Admin Person"), :<, people_links.index("Middle Admin Person")
    assert_operator people_links.index("Middle Admin Person"), :<, people_links.index("Zulu Admin Person")
  end

  test "edit merge people select is alphabetical" do
    person = Person.create!(name: "Edit Target Person")
    Person.create!(name: "Zulu Merge Person")
    Person.create!(name: "Alpha Merge Person")
    Person.create!(name: "Middle Merge Person")

    get edit_guest_path(person)

    assert_response :success
    option_names = css_select("select[name='merge_with_id'] option").map(&:text) - [ "Select person to merge into" ]

    assert_operator option_names.index("Alpha Merge Person"), :<, option_names.index("Middle Merge Person")
    assert_operator option_names.index("Middle Merge Person"), :<, option_names.index("Zulu Merge Person")
  end
end
