# frozen_string_literal: true

# =============================================================================
# Questions and Answers - Building & Facilities Space
# =============================================================================
puts "Creating Facilities questions..."

facilities_space = Space.find_by!(slug: "facilities")

# HVAC complaint
create_qa(
  space: facilities_space,
  author: SEED_BUSINESS_EMPLOYEES["linda.garcia@example.com"],
  title: "3rd floor is FREEZING - can we adjust the thermostat?",
  body: <<~BODY,
    I sit near the windows on the 3rd floor (Building A, zone 3-B) and it's absolutely freezing. I've been wearing a jacket all week.

    - Is there a way to adjust the temperature for our zone?
    - Who do I contact about this?
    - Are space heaters allowed?
  BODY
  answers: [
    {
      author: SEED_FACILITIES_STAFF["tony.russo@example.com"],
      body: <<~ANSWER,
        Sorry to hear you're cold! Here's how our HVAC system works:

        **Temperature Control:**
        - Building is divided into zones controlled by the BMS (Building Management System)
        - Target temperature is 72°F ±2°F
        - Perimeter zones near windows can vary more due to solar gain

        **To Request an Adjustment:**
        1. Submit a Facilities ticket in ServiceNow
        2. Include: Building, floor, zone (check the label on your nearest thermostat)
        3. Describe the issue and approximate time of day

        I'll check the 3-B zone settings today. Often the issue is that dampers get stuck or sensors need recalibration.

        **Space Heaters:**
        - ⚠️ **NOT allowed** due to fire code and electrical load concerns
        - Exception: ADA accommodations (contact HR)
        - Instead, we can provide:
          - Desk fans to redirect air flow
          - Heated keyboard/mouse pads (upon request)
          - Relocation to a warmer area if chronic issue

        I'll follow up on your ticket within 24 hours!
      ANSWER
      votes: 18,
      correct: true
    },
    {
      author: SEED_BUSINESS_EMPLOYEES["tom.bradley@example.com"],
      body: <<~ANSWER,
        I had the same issue! What worked for me was requesting a "comfort survey" - facilities will put a temperature logger at your desk for a week to get actual data.

        Once they had proof it was consistently 65°F at my desk, they rebalanced the air flow for our section.
      ANSWER
      votes: 12,
      correct: false
    }
  ],
  created_ago: 3.days
)

# Badge access question
create_qa(
  space: facilities_space,
  author: SEED_BUSINESS_EMPLOYEES["charles.allen@example.com"],
  title: "How do I get badge access to the fitness center?",
  body: <<~BODY,
    I just found out we have a fitness center in the basement of Building B!

    How do I get access? My badge currently doesn't work on that door.

    Also - what are the hours and are there showers?
  BODY
  answers: [
    {
      author: SEED_FACILITIES_STAFF["gloria.martinez@example.com"],
      body: <<~ANSWER,
        Yes, we do have a fitness center! Here's what you need to know:

        **Getting Access:**
        1. Read and sign the Fitness Center Waiver (on the HR portal under Forms)
        2. Submit the signed waiver to hr@company.com
        3. Access is typically added within 24-48 hours

        **Hours:**
        - Monday-Friday: 5:30 AM - 9:00 PM
        - Saturday: 7:00 AM - 5:00 PM
        - Sunday: Closed
        - Closed on company holidays

        **Amenities:**
        - Cardio: treadmills, ellipticals, bikes
        - Free weights and machines
        - Stretching/yoga area
        - **Yes, showers!** (Men's and Women's locker rooms)
        - Lockers available (bring your own lock, no overnight storage)
        - Towel service (grab from bin, drop in hamper)

        **Rules:**
        - Wipe down equipment after use
        - 30-minute limit on cardio during peak hours (7-9 AM, 12-1 PM, 5-7 PM)
        - No bags in workout area
        - Report equipment issues to Facilities immediately

        Enjoy your workouts!
      ANSWER
      votes: 29,
      correct: true
    }
  ],
  created_ago: 14.days
)

# Desk setup question
create_qa(
  space: facilities_space,
  author: SEED_BUSINESS_EMPLOYEES["ruth.nelson@example.com"],
  title: "New hire desk setup - what equipment can I request?",
  body: <<~BODY,
    I'm starting next Monday and want to make sure my workspace is set up properly. I have some back issues so ergonomics is important to me.

    What equipment is standard and what can I request?
  BODY
  answers: [
    {
      author: SEED_FACILITIES_STAFF["robert.jenkins@example.com"],
      body: <<~ANSWER,
        Welcome aboard! We want you to be comfortable and productive. Here's our standard setup:

        **Standard Issue (all employees):**
        - Height-adjustable desk (sit/stand)
        - Ergonomic chair (Herman Miller Aeron or equivalent)
        - Monitor arm
        - Laptop stand
        - External keyboard and mouse
        - Desk phone (if required for role)

        **Available Upon Request:**
        - Second monitor (submit IT ticket)
        - Footrest
        - Keyboard tray
        - Document holder
        - Monitor privacy screen
        - Desk lamp
        - Headset

        **Ergonomic Accommodations (for documented needs):**
        - Ergonomic assessment with our certified evaluator
        - Specialized chairs
        - Vertical/split keyboards
        - Trackball/ergonomic mouse
        - Anti-fatigue mat for standing

        **For your back issues:**
        I'd recommend scheduling an ergonomic assessment. Email facilities@company.com and mention you're a new hire with ergonomic concerns. We'll get you set up on your first day if possible.

        **Tip:** Your manager should have submitted a New Hire Setup request. Check with them or IT if your equipment isn't ready by Monday.
      ANSWER
      votes: 35,
      correct: true
    },
    {
      author: SEED_BUSINESS_EMPLOYEES["george.hall@example.com"],
      body: <<~ANSWER,
        The ergonomic assessment is totally worth it! The evaluator came to my desk, watched how I sit/type, and made adjustments. Got a footrest and keyboard tray that made a huge difference.

        Also ask about the monitor arm positioning - most people have their monitors too low.
      ANSWER
      votes: 14,
      correct: false
    }
  ],
  created_ago: 7.days
)

# Conference room question
create_qa(
  space: facilities_space,
  author: SEED_BUSINESS_EMPLOYEES["dorothy.green@example.com"],
  title: "How do I book a conference room for a large meeting (20+ people)?",
  body: <<~BODY,
    I need to schedule a quarterly planning meeting for about 25 people.

    - Where are the large conference rooms?
    - How far in advance can I book?
    - Do I need to do anything special for catering?
  BODY
  answers: [
    {
      author: SEED_FACILITIES_STAFF["gloria.martinez@example.com"],
      body: <<~ANSWER,
        For 25 people, you'll want one of our large conference rooms. Here are your options:

        **Large Conference Rooms (20-30 capacity):**
        - **Redwood** - Building A, 2nd floor (seats 25, video conferencing)
        - **Sequoia** - Building A, 4th floor (seats 30, video conferencing + whiteboard walls)
        - **Aspen** - Building B, 1st floor (seats 24, video conferencing)

        **Booking:**
        - Use Outlook calendar > Add Room > search by capacity
        - Large rooms can be booked up to **90 days** in advance
        - For recurring meetings, max 6 months out
        - Cancel within 24 hours if plans change (these are high-demand!)

        **Catering:**
        - Book separately through CaterCow portal (link on intranet)
        - Order at least **3 business days** in advance
        - Dietary restrictions can be noted in order
        - Facilities will set up tables; you're responsible for cleanup

        **Tips for Large Meetings:**
        - Book 15 min before for setup time
        - Test AV equipment day before (IT can help)
        - Reserve backup room if timing is critical
        - Consider hybrid setup (camera, microphone) for remote attendees

        Need help with anything else? Happy to walk you through the booking system!
      ANSWER
      votes: 22,
      correct: true
    }
  ],
  created_ago: 10.days
)

# Parking question (cross-posting to facilities since it relates to building access)
create_qa(
  space: facilities_space,
  author: SEED_BUSINESS_EMPLOYEES["steve.hoffman@example.com"],
  title: "Building access after hours - what's the process?",
  body: <<~BODY,
    I sometimes need to come in on weekends to wrap up projects. A few questions:

    1. What are the "normal hours" when buildings are open?
    2. Can I get in after hours with my badge?
    3. Is there security on site?
    4. Any rules about working alone in the building?
  BODY
  answers: [
    {
      author: SEED_FACILITIES_STAFF["kim.nguyen@example.com"],
      body: <<~ANSWER,
        Good questions! Here's our after-hours policy:

        **Normal Building Hours:**
        - Monday-Friday: 6:00 AM - 8:00 PM
        - Saturday: 8:00 AM - 2:00 PM
        - Sunday: Closed (badge access only)
        - Holidays: Closed (badge access only)

        **After-Hours Access:**
        - Your badge works 24/7 at designated entrances:
          - Building A: Main lobby (south entrance)
          - Building B: Side entrance (east)
        - Other doors lock after hours and don't accept badge swipes

        **Security:**
        - Guard on duty 24/7 at Building A main lobby
        - After-hours visitors must check in with security
        - Cameras active throughout buildings
        - Emergency call boxes on each floor

        **Working Alone Policy:**
        - Notify security desk when arriving/leaving after hours
        - Keep your phone accessible
        - Familiarize yourself with emergency exits
        - No overnight stays (we do check)

        **Important:** If you're working in labs or areas with hazardous materials, there are additional requirements. Check with your manager or EHS (Environmental Health & Safety).

        Stay safe!
      ANSWER
      votes: 27,
      correct: true
    }
  ],
  created_ago: 20.days
)

# Noise complaint
create_qa(
  space: facilities_space,
  author: SEED_BUSINESS_EMPLOYEES["nancy.white@example.com"],
  title: "Is there a quiet space for focused work? Open office is too noisy",
  body: <<~BODY,
    I love my coworkers but the open office is SO distracting. Constant conversations, phone calls, people walking by...

    Are there quiet rooms or focus spaces I can use when I really need to concentrate?
  BODY
  answers: [
    {
      author: SEED_FACILITIES_STAFF["robert.jenkins@example.com"],
      body: <<~ANSWER,
        Totally understand - we've gotten a lot of this feedback! Here are your options:

        **Phone Booths:**
        - Single-person pods for calls or focused work
        - Building A: 6 pods on floors 2, 3, 4
        - Building B: 4 pods on floors 1, 2
        - First-come, first-served (1 hour max during peak times)
        - Book in Outlook: search "Phone Booth"

        **Focus Rooms:**
        - Small rooms (2-4 person) designated for quiet work
        - "Zen" rooms on each floor (look for green door labels)
        - No phone calls allowed
        - Cannot be booked - just walk in if empty

        **Library:**
        - Building A, 5th floor west wing
        - Strictly silent - no talking, minimal typing
        - Great for deep work, reading, research
        - No food allowed

        **Work-from-Home:**
        - Remember, you can WFH 2 days/week for focused work
        - Coordinate with your team on your "focus days"

        **Coming Soon:**
        We're adding more phone booths next quarter based on feedback. Also piloting "focus hours" (no meetings 9-11 AM) with some teams.

        Would love to hear other ideas - facilities@company.com!
      ANSWER
      votes: 41,
      correct: true
    },
    {
      author: SEED_BUSINESS_EMPLOYEES["betty.young@example.com"],
      body: <<~ANSWER,
        I've started using noise-canceling headphones - game changer! IT can reimburse up to $150 for headphones as a productivity tool. Just submit an expense report.

        Also, the library is AMAZING for focus time. I block 2 hours there twice a week.
      ANSWER
      votes: 24,
      correct: false
    }
  ],
  created_ago: 6.days
)

puts "  Created Facilities questions"
