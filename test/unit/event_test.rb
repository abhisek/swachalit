require 'test_helper'

class EventTest < ActiveSupport::TestCase
  test "should not save event without name" do
    event = Event.new
    assert !event.save
  end

  test "fixture should be valid" do
    e = events(:one)
    assert e.save
  end

  test "end time should not be less than start time" do
    e = events(:one)
    e.end_time = e.start_time - 1.day
    assert !e.save
  end

  test "start time should not be in the past" do
    e = events(:one)
    e.start_time = Time.now - 2.days
    e.end_time = Time.now
    assert !e.save
  end

  test "event notification manager states" do
    e = get_random_new_event()
    e.save

    mc = ::ActionMailer::Base.deliveries.count

    assert e.notification_state == ::EventNotification::STATE_INIT, "state: #{e.notification_state}"
    e.execute_notifications()
    e.reload()

    assert e.notification_state == ::EventNotification::STATE_INITIAL_NOTIFICATIONS, "state: #{e.notification_state}"
    assert ::ActionMailer::Base.deliveries.count > mc
    mc = ::ActionMailer::Base.deliveries.count

    e.execute_first_reminder()
    e.reload()

    assert e.notification_state == ::EventNotification::STATE_FIRST_REMINDER, "state: #{e.notification_state}"
    assert ::ActionMailer::Base.deliveries.count > mc
    mc = ::ActionMailer::Base.deliveries.count

    e.execute_second_reminder()
    e.reload()

    assert e.notification_state == ::EventNotification::STATE_SECOND_REMINDER, "state: #{e.notification_state}"
    assert ::ActionMailer::Base.deliveries.count > mc
    mc = ::ActionMailer::Base.deliveries.count

    e.execute_presentation_update_reminder()
    e.reload()

    assert e.notification_state == ::EventNotification::STATE_PRESENTATION_UPDATE, "state: #{e.notification_state}"
  end

  test "descriptive name" do
    e = events(:one)

    assert e.descriptive_name.index(e.chapter.name) != nil
    assert e.descriptive_name.index(e.event_type.name) != nil
    assert e.descriptive_name.index(e.start_time.strftime('%d %B %Y')) != nil
  end

  test "descriptive start time" do
    e = events(:one)
    assert e.descriptive_start_time.index(e.start_time.year.to_s) != nil
  end

  test "user managed chapters" do
    u = users(:one)

    assert u.managed_chapters.is_a?(::Array)
  end

  test "user managed venues" do
    u = users(:one)

    assert u.managed_venues.is_a?(::ActiveRecord::Relation)
    assert u.managed_venues.map(&:id).include?(1)
    assert !u.managed_venues.map(&:id).include?(2)
  end

  test "calendar update" do
    e = events(:one)

    begin
      e.event_update_calendar()
      assert false, "Should trigger exception"
    rescue => e
      # We are not supplying a valid key file during testing
      assert e.class.to_s == "ArgumentError"
      assert e.message == "Invalid keyfile or passphrase"
    end
  end

  test "event name update" do
    e = events(:one)
    e.name = "NEW NAME 1111"
    assert e.save

    assert e.name == "NEW NAME 1111"
    assert !e.descriptive_name.index("NEW NAME 1111").nil?
    assert !e.descriptive_name.index(chapters(:one).name).nil?
  end

  test "chapter must be active" do
    e = events(:one)
    c = e.chapter
    c.active = false
    assert c.save

    e.name = "NEW NAME"
    assert_not e.save

    c = chapters(:one)
    c.active = false
    assert c.save

    e = get_random_new_event()
    e.chapter = c
    assert_not e.save
  end
end
