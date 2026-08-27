# Demo data: wipe and recreate so `db:seed` always yields the four
# interesting states (upcoming, due today, overdue, completed).
Task.destroy_all

Task.create!(
  title: "Prepare September board packet",
  description: "Assemble financials, manager report and agenda.",
  due_at: 5.days.from_now.change(hour: 17)
)

Task.create!(
  title: "Email the annual meeting notice",
  description: "Send to all unit owners.",
  due_at: Time.zone.now.end_of_day - 2.hours
)

Task.create!(
  title: "File the elevator inspection report",
  description: "Was due last week \u2014 chase the vendor.",
  due_at: 6.days.ago.change(hour: 9)
)

Task.create!(
  title: "Renew building insurance policy",
  description: "Confirmed with the broker.",
  due_at: 2.days.ago.change(hour: 12),
  completed_at: 3.days.ago
)

puts "Seeded #{Task.count} tasks."
