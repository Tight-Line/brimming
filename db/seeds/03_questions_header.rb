# frozen_string_literal: true

# =============================================================================
# Questions and Answers - Setup
# =============================================================================
# This file sets up shared user lookups used by all space-specific question files.
# It is loaded before the individual space files (03a_, 03b_, etc.)

puts "Setting up question seed data..."

# Look up users by their characteristics - these will be used by subsequent files
SEED_EXPERTS = User.where(email: [
  "dr.james.wilson@example.com",
  "prof.aisha.patel@example.com",
  "senior.dev.mike@example.com",
  "architect.lisa@example.com",
  "principal.eng.tom@example.com",
  "staff.eng.nina@example.com",
  "tech.lead.omar@example.com",
  "senior.rachel@example.com",
  "architect.sam@example.com",
  "distinguished.eng@example.com"
]).index_by(&:email).freeze

SEED_INTERMEDIATES = User.where(email: [
  "dev.ashley@example.com",
  "coder.brian@example.com",
  "fullstack.carol@example.com",
  "backend.david@example.com",
  "frontend.emma@example.com",
  "junior.frank@example.com",
  "learner.grace@example.com",
  "dev.hannah@example.com",
  "coder.ian@example.com",
  "web.julia@example.com",
  "backend.kevin@example.com",
  "fullstack.laura@example.com",
  "dev.marcus@example.com",
  "frontend.nadia@example.com"
]).index_by(&:email).freeze

SEED_NEWBIES = User.where(email: [
  "newbie.henry@example.com",
  "student.ivy@example.com",
  "beginner.jack@example.com",
  "learning.kate@example.com",
  "first.timer.leo@example.com",
  "newdev.maya@example.com",
  "student.nathan@example.com",
  "bootcamp.olivia@example.com",
  "learner.pedro@example.com",
  "beginner.quinn@example.com"
]).index_by(&:email).freeze

SEED_MODERATORS = User.where(email: [
  "sarah.chen@example.com",
  "marcus.johnson@example.com",
  "elena.rodriguez@example.com"
]).index_by(&:email).freeze

# =============================================================================
# Business Users
# =============================================================================

# HR Department
SEED_HR_STAFF = User.where(email: [
  "patricia.wells@example.com",      # HR Director
  "daniel.oconnor@example.com",      # Benefits Manager
  "maria.santos@example.com",        # Recruiter
  "james.wright@example.com"         # HR Coordinator
]).index_by(&:email).freeze

# Facilities & Building Maintenance
SEED_FACILITIES_STAFF = User.where(email: [
  "robert.jenkins@example.com",      # Facilities Director
  "gloria.martinez@example.com",     # Office Manager
  "tony.russo@example.com",          # Maintenance Lead
  "kim.nguyen@example.com"           # Safety Coordinator
]).index_by(&:email).freeze

# Finance & Accounting
SEED_FINANCE_STAFF = User.where(email: [
  "elizabeth.moore@example.com",     # CFO
  "richard.chang@example.com",       # Controller
  "susan.baker@example.com",         # AP Manager
  "michael.torres@example.com",      # Payroll Specialist
  "jennifer.kim@example.com"         # Staff Accountant
]).index_by(&:email).freeze

# Product Management
SEED_PRODUCT_STAFF = User.where(email: [
  "amanda.foster@example.com",       # VP Product
  "derek.washington@example.com",    # Sr PM
  "lisa.bernstein@example.com",      # PM
  "raj.patel@example.com",           # Associate PM
  "casey.miller@example.com"         # Product Analyst
]).index_by(&:email).freeze

# Project Management Office
SEED_PMO_STAFF = User.where(email: [
  "stephanie.clark@example.com",     # PMO Director
  "brandon.lee@example.com",         # Sr Project Manager
  "nicole.adams@example.com",        # Project Manager
  "chris.taylor@example.com",        # Scrum Master
  "amy.wilson@example.com"           # Project Coordinator
]).index_by(&:email).freeze

# Travel & Admin
SEED_TRAVEL_STAFF = User.where(email: [
  "barbara.stone@example.com",       # Travel Manager
  "kevin.murphy@example.com",        # Admin Services Mgr
  "diane.cooper@example.com",        # Executive Assistant
  "jason.reed@example.com"           # Office Coordinator
]).index_by(&:email).freeze

# Regular Business Employees
SEED_BUSINESS_EMPLOYEES = User.where(email: [
  "steve.hoffman@example.com",
  "linda.garcia@example.com",
  "tom.bradley@example.com",
  "nancy.white@example.com",
  "george.hall@example.com",
  "betty.young@example.com",
  "charles.allen@example.com",
  "margaret.king@example.com",
  "joe.scott@example.com",
  "dorothy.green@example.com",
  "paul.adams@example.com",
  "ruth.nelson@example.com"
]).index_by(&:email).freeze

puts "  Loaded user data for questions"
