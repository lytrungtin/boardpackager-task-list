# Demo data: wipe and recreate so `db:seed` always yields two demo users
# and the four interesting task states (upcoming, due today, overdue,
# completed). Users are managed here / via console per the brief — no
# sign-up flow or admin account needed.
Task.destroy_all
Session.destroy_all
User.destroy_all

alice = User.create!(email_address: "alice@example.com", password: "password")
bob = User.create!(email_address: "bob@example.com", password: "password")

alice.tasks.create!(
  title: "Prepare September board packet",
  description: "Assemble financials, manager report and agenda.",
  due_at: 5.days.from_now.change(hour: 17)
)

alice.tasks.create!(
  title: "Email the annual meeting notice",
  description: "Send to all unit owners.",
  due_at: Time.zone.now.end_of_day - 2.hours
)

alice.tasks.create!(
  title: "File the elevator inspection report",
  description: "Was due last week \u2014 chase the vendor.",
  due_at: 6.days.ago.change(hour: 9)
)

alice.tasks.create!(
  title: "Renew building insurance policy",
  description: "Confirmed with the broker.",
  due_at: 2.days.ago.change(hour: 12),
  completed_at: 3.days.ago
)

bob.tasks.create!(
  title: "Walk the property with the super",
  description: "Quarterly inspection round.",
  due_at: 1.day.from_now.change(hour: 10)
)

puts "Seeded #{User.count} users and #{Task.count} tasks."
puts "Sign in as alice@example.com / password (or bob@example.com / password)."
