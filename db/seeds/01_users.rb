# frozen_string_literal: true

# =============================================================================
# Users
# =============================================================================
puts "Creating users..."

# Admin user
admin = User.find_or_create_by!(email: "admin@example.com") do |u|
  u.username = "admin"
  u.full_name = "System Administrator"
  u.password = DEFAULT_PASSWORD
  u.role = :admin
  u.avatar_url = "https://api.dicebear.com/7.x/identicon/svg?seed=admin"
end

# System robot user (for AI-generated content)
robot_avatar = "https://api.dicebear.com/7.x/bottts-neutral/svg?seed=magic-helper&backgroundColor=b6e3f4&eyes=bulging&mouth=smile01"
robot = User.find_or_create_by!(email: "robot@system.local") do |u|
  u.username = "helpful_robot"
  u.full_name = "Helpful Robot"
  u.password = SecureRandom.hex(32) # Random password - robot cannot log in
  u.role = :system
  # Fun colorful robot with smiling face - matches Q&A Wizard magic theme
  u.avatar_url = robot_avatar
end
# Always update avatar to latest design
robot.update!(avatar_url: robot_avatar) if robot.avatar_url != robot_avatar

# Moderators
moderators = [
  { email: "sarah.chen@example.com", username: "sarahc", full_name: "Sarah Chen" },
  { email: "marcus.johnson@example.com", username: "mjohnson", full_name: "Marcus Johnson" },
  { email: "elena.rodriguez@example.com", username: "erodriguez", full_name: "Elena Rodriguez" }
].map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.username = attrs[:username]
    u.full_name = attrs[:full_name]
    u.password = DEFAULT_PASSWORD
    u.avatar_url = "https://api.dicebear.com/7.x/identicon/svg?seed=#{attrs[:username]}"
  end
end

# Expert users (high activity, well-written questions/answers)
experts = [
  { email: "dr.james.wilson@example.com", username: "drjwilson", full_name: "Dr. James Wilson" },
  { email: "prof.aisha.patel@example.com", username: "apatel_prof", full_name: "Prof. Aisha Patel" },
  { email: "senior.dev.mike@example.com", username: "mike_seniordev", full_name: "Mike Thompson" },
  { email: "architect.lisa@example.com", username: "lisa_architect", full_name: "Lisa Chen" },
  { email: "principal.eng.tom@example.com", username: "tom_principal", full_name: "Tom Anderson" },
  { email: "staff.eng.nina@example.com", username: "nina_staff", full_name: "Nina Kozlov" },
  { email: "tech.lead.omar@example.com", username: "omar_techlead", full_name: "Omar Hassan" },
  { email: "senior.rachel@example.com", username: "rachel_senior", full_name: "Rachel Kim" },
  { email: "architect.sam@example.com", username: "sam_arch", full_name: "Sam Nakamura" },
  { email: "distinguished.eng@example.com", username: "victor_dist", full_name: "Victor Okonkwo" }
].map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.username = attrs[:username]
    u.full_name = attrs[:full_name]
    u.password = DEFAULT_PASSWORD
    u.role = :user
    u.avatar_url = "https://api.dicebear.com/7.x/identicon/svg?seed=#{attrs[:username]}"
  end
end

# Intermediate users
intermediates = [
  { email: "dev.ashley@example.com", username: "ashley_dev", full_name: "Ashley Brooks" },
  { email: "coder.brian@example.com", username: "brian_codes", full_name: "Brian Chen" },
  { email: "fullstack.carol@example.com", username: "carol_fs", full_name: "Carol Davis" },
  { email: "backend.david@example.com", username: "david_backend", full_name: "David Evans" },
  { email: "frontend.emma@example.com", username: "emma_frontend", full_name: "Emma Foster" },
  { email: "junior.frank@example.com", username: "frank_jr" },
  { email: "learner.grace@example.com", username: "grace_learning" },
  { email: "dev.hannah@example.com", username: "hannah_dev", full_name: "Hannah Garcia" },
  { email: "coder.ian@example.com", username: "ian_codes", full_name: "Ian Hughes" },
  { email: "web.julia@example.com", username: "julia_web", full_name: "Julia Ivanova" },
  { email: "backend.kevin@example.com", username: "kevin_backend" },
  { email: "fullstack.laura@example.com", username: "laura_fs", full_name: "Laura Martinez" },
  { email: "dev.marcus@example.com", username: "marcus_dev", full_name: "Marcus Brown" },
  { email: "frontend.nadia@example.com", username: "nadia_frontend", full_name: "Nadia Shah" }
].map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.username = attrs[:username]
    u.full_name = attrs[:full_name]
    u.password = DEFAULT_PASSWORD
    u.role = :user
    u.avatar_url = "https://api.dicebear.com/7.x/identicon/svg?seed=#{attrs[:username]}"
  end
end

# Newbie users (often poorly-phrased questions)
newbies = [
  { email: "newbie.henry@example.com", username: "henry_newbie" },
  { email: "student.ivy@example.com", username: "ivy_student" },
  { email: "beginner.jack@example.com", username: "jack_beginner" },
  { email: "learning.kate@example.com", username: "kate_learn" },
  { email: "first.timer.leo@example.com", username: "leo_firsttime" },
  { email: "newdev.maya@example.com", username: "maya_newdev" },
  { email: "student.nathan@example.com", username: "nathan_student" },
  { email: "bootcamp.olivia@example.com", username: "olivia_bootcamp" },
  { email: "learner.pedro@example.com", username: "pedro_learns" },
  { email: "beginner.quinn@example.com", username: "quinn_beginner" }
].map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.username = attrs[:username]
    u.password = DEFAULT_PASSWORD
    u.role = :user
    u.avatar_url = "https://api.dicebear.com/7.x/identicon/svg?seed=#{attrs[:username]}"
  end
end

# =============================================================================
# Business Users (non-technical staff)
# =============================================================================

# HR Department
hr_staff = [
  { email: "patricia.wells@example.com", username: "pwells", full_name: "Patricia Wells" },      # HR Director
  { email: "daniel.oconnor@example.com", username: "doconnor", full_name: "Daniel O'Connor" },  # Benefits Manager
  { email: "maria.santos@example.com", username: "msantos", full_name: "Maria Santos" },        # Recruiter
  { email: "james.wright@example.com", username: "jwright", full_name: "James Wright" }         # HR Coordinator
].map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.username = attrs[:username]
    u.full_name = attrs[:full_name]
    u.password = DEFAULT_PASSWORD
    u.role = :user
    u.avatar_url = "https://api.dicebear.com/7.x/identicon/svg?seed=#{attrs[:username]}"
  end
end

# Facilities & Building Maintenance
facilities_staff = [
  { email: "robert.jenkins@example.com", username: "rjenkins", full_name: "Robert Jenkins" },   # Facilities Director
  { email: "gloria.martinez@example.com", username: "gmartinez", full_name: "Gloria Martinez" }, # Office Manager
  { email: "tony.russo@example.com", username: "trusso", full_name: "Tony Russo" },             # Maintenance Lead
  { email: "kim.nguyen@example.com", username: "knguyen", full_name: "Kim Nguyen" }             # Safety Coordinator
].map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.username = attrs[:username]
    u.full_name = attrs[:full_name]
    u.password = DEFAULT_PASSWORD
    u.role = :user
    u.avatar_url = "https://api.dicebear.com/7.x/identicon/svg?seed=#{attrs[:username]}"
  end
end

# Finance & Accounting
finance_staff = [
  { email: "elizabeth.moore@example.com", username: "emoore", full_name: "Elizabeth Moore" },   # CFO
  { email: "richard.chang@example.com", username: "rchang", full_name: "Richard Chang" },       # Controller
  { email: "susan.baker@example.com", username: "sbaker", full_name: "Susan Baker" },           # AP Manager
  { email: "michael.torres@example.com", username: "mtorres", full_name: "Michael Torres" },    # Payroll Specialist
  { email: "jennifer.kim@example.com", username: "jkim", full_name: "Jennifer Kim" }            # Staff Accountant
].map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.username = attrs[:username]
    u.full_name = attrs[:full_name]
    u.password = DEFAULT_PASSWORD
    u.role = :user
    u.avatar_url = "https://api.dicebear.com/7.x/identicon/svg?seed=#{attrs[:username]}"
  end
end

# Product Management
product_staff = [
  { email: "amanda.foster@example.com", username: "afoster", full_name: "Amanda Foster" },      # VP Product
  { email: "derek.washington@example.com", username: "dwashington", full_name: "Derek Washington" }, # Sr PM
  { email: "lisa.bernstein@example.com", username: "lbernstein", full_name: "Lisa Bernstein" }, # PM
  { email: "raj.patel@example.com", username: "rpatel", full_name: "Raj Patel" },               # Associate PM
  { email: "casey.miller@example.com", username: "cmiller", full_name: "Casey Miller" }         # Product Analyst
].map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.username = attrs[:username]
    u.full_name = attrs[:full_name]
    u.password = DEFAULT_PASSWORD
    u.role = :user
    u.avatar_url = "https://api.dicebear.com/7.x/identicon/svg?seed=#{attrs[:username]}"
  end
end

# Project Management Office
pmo_staff = [
  { email: "stephanie.clark@example.com", username: "sclark", full_name: "Stephanie Clark" },   # PMO Director
  { email: "brandon.lee@example.com", username: "blee", full_name: "Brandon Lee" },             # Sr Project Manager
  { email: "nicole.adams@example.com", username: "nadams", full_name: "Nicole Adams" },         # Project Manager
  { email: "chris.taylor@example.com", username: "ctaylor", full_name: "Chris Taylor" },        # Scrum Master
  { email: "amy.wilson@example.com", username: "awilson", full_name: "Amy Wilson" }             # Project Coordinator
].map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.username = attrs[:username]
    u.full_name = attrs[:full_name]
    u.password = DEFAULT_PASSWORD
    u.role = :user
    u.avatar_url = "https://api.dicebear.com/7.x/identicon/svg?seed=#{attrs[:username]}"
  end
end

# Travel & Admin
travel_admin_staff = [
  { email: "barbara.stone@example.com", username: "bstone", full_name: "Barbara Stone" },       # Travel Manager
  { email: "kevin.murphy@example.com", username: "kmurphy", full_name: "Kevin Murphy" },        # Admin Services Mgr
  { email: "diane.cooper@example.com", username: "dcooper", full_name: "Diane Cooper" },        # Executive Assistant
  { email: "jason.reed@example.com", username: "jreed", full_name: "Jason Reed" }               # Office Coordinator
].map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.username = attrs[:username]
    u.full_name = attrs[:full_name]
    u.password = DEFAULT_PASSWORD
    u.role = :user
    u.avatar_url = "https://api.dicebear.com/7.x/identicon/svg?seed=#{attrs[:username]}"
  end
end

# Regular employees (ask questions on business topics)
business_employees = [
  { email: "steve.hoffman@example.com", username: "shoffman", full_name: "Steve Hoffman" },
  { email: "linda.garcia@example.com", username: "lgarcia", full_name: "Linda Garcia" },
  { email: "tom.bradley@example.com", username: "tbradley", full_name: "Tom Bradley" },
  { email: "nancy.white@example.com", username: "nwhite", full_name: "Nancy White" },
  { email: "george.hall@example.com", username: "ghall", full_name: "George Hall" },
  { email: "betty.young@example.com", username: "byoung", full_name: "Betty Young" },
  { email: "charles.allen@example.com", username: "callen", full_name: "Charles Allen" },
  { email: "margaret.king@example.com", username: "mking", full_name: "Margaret King" },
  { email: "joe.scott@example.com", username: "jscott", full_name: "Joe Scott" },
  { email: "dorothy.green@example.com", username: "dgreen", full_name: "Dorothy Green" },
  { email: "paul.adams@example.com", username: "padams", full_name: "Paul Adams" },
  { email: "ruth.nelson@example.com", username: "rnelson", full_name: "Ruth Nelson" }
].map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.username = attrs[:username]
    u.full_name = attrs[:full_name]
    u.password = DEFAULT_PASSWORD
    u.role = :user
    u.avatar_url = "https://api.dicebear.com/7.x/identicon/svg?seed=#{attrs[:username]}"
  end
end

all_users = [ admin, robot ] + moderators + experts + intermediates + newbies +
            hr_staff + facilities_staff + finance_staff + product_staff +
            pmo_staff + travel_admin_staff + business_employees

puts "  Created #{all_users.count} users (including system robot)"
