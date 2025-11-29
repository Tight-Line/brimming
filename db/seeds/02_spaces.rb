# frozen_string_literal: true

# =============================================================================
# Spaces
# =============================================================================
puts "Creating spaces..."

spaces_data = [
  {
    name: "Ruby on Rails",
    slug: "ruby-on-rails",
    description: "Questions about Ruby on Rails web framework, including ActiveRecord, ActionController, and Rails best practices."
  },
  {
    name: "JavaScript",
    slug: "javascript",
    description: "Questions about JavaScript, ES6+, async programming, DOM manipulation, and browser APIs."
  },
  {
    name: "Python",
    slug: "python",
    description: "Questions about Python programming, including Django, Flask, data science libraries, and Pythonic practices."
  },
  {
    name: "DevOps",
    slug: "devops",
    description: "Questions about CI/CD, Docker, Kubernetes, infrastructure as code, and deployment strategies."
  },
  {
    name: "Databases",
    slug: "databases",
    description: "Questions about SQL, NoSQL, database design, query optimization, and data modeling."
  },
  {
    name: "Security",
    slug: "security",
    description: "Questions about application security, authentication, authorization, and secure coding practices."
  },
  {
    name: "Architecture",
    slug: "architecture",
    description: "Questions about software architecture, design patterns, microservices, and system design."
  },
  {
    name: "Testing",
    slug: "testing",
    description: "Questions about unit testing, integration testing, TDD, and testing frameworks."
  },
  # Empty spaces (no questions yet)
  {
    name: "Rust",
    slug: "rust",
    description: "Questions about Rust programming language, memory safety, ownership, and systems programming."
  },
  {
    name: "Go",
    slug: "go",
    description: "Questions about Go (Golang), concurrency patterns, goroutines, and building scalable services."
  },
  {
    name: "Machine Learning",
    slug: "machine-learning",
    description: "Questions about ML algorithms, neural networks, training models, and AI applications."
  },
  {
    name: "Mobile Development",
    slug: "mobile-development",
    description: "Questions about iOS, Android, React Native, Flutter, and cross-platform mobile development."
  },
  # =============================================================================
  # Business/Non-Technical Spaces
  # =============================================================================
  {
    name: "Human Resources",
    slug: "human-resources",
    description: "Questions about HR policies, benefits, onboarding, performance reviews, PTO, and employee relations."
  },
  {
    name: "Building & Facilities",
    slug: "facilities",
    description: "Questions about office facilities, building maintenance, HVAC, security badges, desk assignments, and workspace issues."
  },
  {
    name: "Parking & Commuting",
    slug: "parking",
    description: "Questions about parking permits, garage access, commuter benefits, bike storage, and transportation options."
  },
  {
    name: "Travel & Expenses",
    slug: "travel",
    description: "Questions about business travel policies, expense reports, booking procedures, per diem rates, and reimbursements."
  },
  {
    name: "Product Management",
    slug: "product-management",
    description: "Questions about product strategy, roadmaps, feature prioritization, user research, and product lifecycle management."
  },
  {
    name: "Project Management",
    slug: "project-management",
    description: "Questions about project planning, Agile methodologies, sprint management, resource allocation, and delivery timelines."
  },
  {
    name: "Finance & Accounting",
    slug: "finance",
    description: "Questions about budgets, purchase orders, invoice processing, financial reporting, and accounting procedures."
  },
  {
    name: "Office Services",
    slug: "office-services",
    description: "Questions about office supplies, mail services, conference room booking, catering, and administrative support."
  }
]

spaces = spaces_data.map do |attrs|
  Space.find_or_create_by!(slug: attrs[:slug]) do |s|
    s.name = attrs[:name]
    s.description = attrs[:description]
  end
end

puts "  Created #{spaces.count} spaces"

# Assign space moderators
puts "Assigning space moderators..."

# Look up users and spaces by their attributes
moderators = User.where(email: [
  "sarah.chen@example.com",
  "marcus.johnson@example.com",
  "elena.rodriguez@example.com"
]).order(:email).to_a

experts = User.where(email: "senior.dev.mike@example.com").to_a

rails_space = Space.find_by!(slug: "ruby-on-rails")
js_space = Space.find_by!(slug: "javascript")
python_space = Space.find_by!(slug: "python")
devops_space = Space.find_by!(slug: "devops")

# elena, marcus, sarah (alphabetically by email)
rails_space.add_moderator(moderators[2]) # sarah
rails_space.add_moderator(experts[0]) if experts[0] # mike
js_space.add_moderator(moderators[1]) # marcus
python_space.add_moderator(moderators[0]) # elena
devops_space.add_moderator(moderators[2]) # sarah

# Assign moderators to business spaces
hr_space = Space.find_by!(slug: "human-resources")
facilities_space = Space.find_by!(slug: "facilities")
parking_space = Space.find_by!(slug: "parking")
travel_space = Space.find_by!(slug: "travel")
product_space = Space.find_by!(slug: "product-management")
project_space = Space.find_by!(slug: "project-management")
finance_space = Space.find_by!(slug: "finance")
office_space = Space.find_by!(slug: "office-services")

# Look up business staff
hr_director = User.find_by(email: "patricia.wells@example.com")
facilities_director = User.find_by(email: "robert.jenkins@example.com")
travel_manager = User.find_by(email: "barbara.stone@example.com")
vp_product = User.find_by(email: "amanda.foster@example.com")
pmo_director = User.find_by(email: "stephanie.clark@example.com")
cfo = User.find_by(email: "elizabeth.moore@example.com")
office_manager = User.find_by(email: "gloria.martinez@example.com")

hr_space.add_moderator(hr_director) if hr_director
facilities_space.add_moderator(facilities_director) if facilities_director
parking_space.add_moderator(facilities_director) if facilities_director # Parking falls under facilities
travel_space.add_moderator(travel_manager) if travel_manager
product_space.add_moderator(vp_product) if vp_product
project_space.add_moderator(pmo_director) if pmo_director
finance_space.add_moderator(cfo) if cfo
office_space.add_moderator(office_manager) if office_manager

puts "  Assigned moderators to spaces"
