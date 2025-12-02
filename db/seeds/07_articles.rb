# frozen_string_literal: true

# =============================================================================
# Articles
# =============================================================================
puts "Creating articles..."

# Helper to create an article
def create_article(author:, title:, body:, spaces:, created_ago: rand(1..60).days)
  article = Article.find_or_create_by!(title: title) do |a|
    a.user = author
    a.body = body
    a.content_type = "markdown"
    a.created_at = created_ago.ago
    a.updated_at = created_ago.ago
  end

  # Associate with spaces
  spaces.each do |space|
    ArticleSpace.find_or_create_by!(article: article, space: space)
  end

  article
end

# Find spaces
rails_space = Space.find_by!(slug: "ruby-on-rails")
js_space = Space.find_by!(slug: "javascript")
python_space = Space.find_by!(slug: "python")
devops_space = Space.find_by!(slug: "devops")
databases_space = Space.find_by!(slug: "databases")
security_space = Space.find_by!(slug: "security")
architecture_space = Space.find_by!(slug: "architecture")
testing_space = Space.find_by!(slug: "testing")
hr_space = Space.find_by!(slug: "human-resources")
facilities_space = Space.find_by!(slug: "facilities")
travel_space = Space.find_by!(slug: "travel")
finance_space = Space.find_by!(slug: "finance")
product_space = Space.find_by!(slug: "product-management")
project_space = Space.find_by!(slug: "project-management")

# Find authors (space publishers)
mike = User.find_by!(email: "senior.dev.mike@example.com")
sarah = User.find_by!(email: "sarah.chen@example.com")
marcus = User.find_by!(email: "marcus.johnson@example.com")
elena = User.find_by!(email: "elena.rodriguez@example.com")
aisha = User.find_by!(email: "prof.aisha.patel@example.com")
omar = User.find_by!(email: "tech.lead.omar@example.com")
hr_director = User.find_by!(email: "patricia.wells@example.com")
facilities_director = User.find_by!(email: "robert.jenkins@example.com")
travel_manager = User.find_by!(email: "barbara.stone@example.com")
cfo = User.find_by!(email: "elizabeth.moore@example.com")
vp_product = User.find_by!(email: "amanda.foster@example.com")
pmo_director = User.find_by!(email: "stephanie.clark@example.com")

articles = []

# =============================================================================
# Ruby on Rails Articles
# =============================================================================

articles << create_article(
  author: mike,
  title: "Rails 8 Upgrade Guide: What You Need to Know",
  body: <<~MARKDOWN,
    ## Introduction

    Rails 8 brings exciting new features and improvements. This guide will help you upgrade your application smoothly.

    ## Key Changes

    ### 1. Solid Queue as Default

    Rails 8 ships with Solid Queue as the default Active Job backend. This eliminates the need for Redis in many applications.

    ```ruby
    # config/application.rb
    config.active_job.queue_adapter = :solid_queue
    ```

    ### 2. Solid Cache Integration

    The new Solid Cache provides a database-backed cache store that works great for most applications.

    ### 3. Kamal 2 Deployment

    Kamal 2 is now the recommended deployment solution, offering zero-downtime deployments out of the box.

    ## Upgrade Steps

    1. Update your Gemfile to Rails 8.0
    2. Run `bundle update rails`
    3. Run `rails app:update`
    4. Review and merge the generated changes
    5. Run your test suite
    6. Deploy to staging first

    ## Common Issues

    ### Asset Pipeline Changes

    If you're using Sprockets, consider migrating to Propshaft or import maps.

    ### Action Cable Configuration

    Review your Action Cable configuration as there are some changes to the default adapter.

    ## Conclusion

    Rails 8 is a solid release that simplifies deployment and reduces dependencies. Take your time with the upgrade and test thoroughly.
  MARKDOWN
  spaces: [ rails_space ],
  created_ago: 5.days
)

articles << create_article(
  author: sarah,
  title: "Best Practices for Rails API Design",
  body: <<~MARKDOWN,
    ## Overview

    Building a well-designed API is crucial for maintainability and developer experience. Here are our recommended best practices.

    ## Versioning

    Always version your API from day one:

    ```ruby
    # config/routes.rb
    namespace :api do
      namespace :v1 do
        resources :users, only: [:index, :show, :create, :update]
      end
    end
    ```

    ## Response Structure

    Use consistent response structures:

    ```json
    {
      "data": {
        "id": 1,
        "type": "user",
        "attributes": {
          "email": "user@example.com",
          "name": "John Doe"
        }
      },
      "meta": {
        "timestamp": "2024-01-15T10:30:00Z"
      }
    }
    ```

    ## Error Handling

    Return meaningful error responses:

    ```ruby
    class Api::V1::BaseController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActionController::ParameterMissing, with: :bad_request

      private

      def not_found(exception)
        render json: { error: exception.message }, status: :not_found
      end

      def bad_request(exception)
        render json: { error: exception.message }, status: :bad_request
      end
    end
    ```

    ## Authentication

    Use token-based authentication (JWT or API keys) for stateless APIs.

    ## Rate Limiting

    Implement rate limiting to protect your API from abuse.

    ## Documentation

    Always document your API. Consider using OpenAPI/Swagger.
  MARKDOWN
  spaces: [ rails_space, architecture_space ],
  created_ago: 12.days
)

# =============================================================================
# JavaScript Articles
# =============================================================================

articles << create_article(
  author: marcus,
  title: "Modern JavaScript: ES2024 Features You Should Know",
  body: <<~MARKDOWN,
    ## Introduction

    ECMAScript 2024 introduces several new features that make JavaScript development more enjoyable. Let's explore the highlights.

    ## Array Grouping

    The new `Object.groupBy()` and `Map.groupBy()` methods make grouping array elements trivial:

    ```javascript
    const items = [
      { name: 'apple', type: 'fruit' },
      { name: 'carrot', type: 'vegetable' },
      { name: 'banana', type: 'fruit' }
    ];

    const grouped = Object.groupBy(items, item => item.type);
    // { fruit: [...], vegetable: [...] }
    ```

    ## Promise.withResolvers()

    Create promise, resolve, and reject functions together:

    ```javascript
    const { promise, resolve, reject } = Promise.withResolvers();

    // Use resolve/reject anywhere
    setTimeout(() => resolve('done'), 1000);
    ```

    ## Well-Formed Unicode Strings

    New methods for handling Unicode strings properly:

    ```javascript
    const str = 'Hello\\uD800World';
    str.isWellFormed(); // false
    str.toWellFormed(); // 'Hello\\uFFFDWorld'
    ```

    ## Resizable ArrayBuffers

    ArrayBuffers can now be resized:

    ```javascript
    const buffer = new ArrayBuffer(8, { maxByteLength: 16 });
    buffer.resize(12);
    ```

    ## Conclusion

    These features improve JavaScript's expressiveness and capability. Check your target environment's support before using them in production.
  MARKDOWN
  spaces: [ js_space ],
  created_ago: 8.days
)

# =============================================================================
# Python Articles
# =============================================================================

articles << create_article(
  author: aisha,
  title: "Python Type Hints: A Comprehensive Guide",
  body: <<~MARKDOWN,
    ## Why Type Hints?

    Type hints improve code readability, enable better IDE support, and catch bugs early with static analysis tools.

    ## Basic Types

    ```python
    def greet(name: str) -> str:
        return f"Hello, {name}!"

    def calculate(x: int, y: int) -> float:
        return x / y

    def process(data: list[str]) -> dict[str, int]:
        return {item: len(item) for item in data}
    ```

    ## Optional and Union Types

    ```python
    from typing import Optional, Union

    def find_user(id: int) -> Optional[User]:
        return User.query.get(id)

    def parse_value(value: Union[str, int]) -> str:
        return str(value)

    # Python 3.10+ syntax
    def parse_value(value: str | int) -> str:
        return str(value)
    ```

    ## Generic Types

    ```python
    from typing import TypeVar, Generic

    T = TypeVar('T')

    class Container(Generic[T]):
        def __init__(self, value: T) -> None:
            self.value = value

        def get(self) -> T:
            return self.value
    ```

    ## TypedDict for Structured Dictionaries

    ```python
    from typing import TypedDict

    class UserDict(TypedDict):
        name: str
        email: str
        age: int

    def create_user(data: UserDict) -> User:
        return User(**data)
    ```

    ## Using mypy

    Run mypy to check your type hints:

    ```bash
    pip install mypy
    mypy your_module.py
    ```

    ## Conclusion

    Start adding type hints gradually. They're optional but incredibly valuable for large codebases.
  MARKDOWN
  spaces: [ python_space ],
  created_ago: 15.days
)

# =============================================================================
# DevOps Articles
# =============================================================================

articles << create_article(
  author: omar,
  title: "Kubernetes Best Practices for Production",
  body: <<~MARKDOWN,
    ## Introduction

    Running Kubernetes in production requires careful consideration of security, reliability, and performance.

    ## Resource Management

    Always specify resource requests and limits:

    ```yaml
    resources:
      requests:
        memory: "256Mi"
        cpu: "250m"
      limits:
        memory: "512Mi"
        cpu: "500m"
    ```

    ## Health Checks

    Implement proper liveness and readiness probes:

    ```yaml
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10

    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
    ```

    ## Pod Disruption Budgets

    Protect your applications during voluntary disruptions:

    ```yaml
    apiVersion: policy/v1
    kind: PodDisruptionBudget
    metadata:
      name: my-app-pdb
    spec:
      minAvailable: 2
      selector:
        matchLabels:
          app: my-app
    ```

    ## Network Policies

    Implement network policies to control pod communication:

    ```yaml
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: api-ingress
    spec:
      podSelector:
        matchLabels:
          app: api
      ingress:
        - from:
            - podSelector:
                matchLabels:
                  app: frontend
          ports:
            - port: 8080
    ```

    ## Secrets Management

    Never store secrets in ConfigMaps. Use Secrets with encryption at rest, or external secret managers.

    ## Monitoring

    Implement comprehensive monitoring with Prometheus and Grafana.
  MARKDOWN
  spaces: [ devops_space, architecture_space ],
  created_ago: 20.days
)

# =============================================================================
# HR Articles
# =============================================================================

articles << create_article(
  author: hr_director,
  title: "2024 Employee Benefits Guide",
  body: <<~MARKDOWN,
    ## Overview

    This guide outlines the benefits available to all full-time employees effective January 1, 2024.

    ## Health Insurance

    ### Medical Plans

    We offer three medical plan options:

    | Plan | Monthly Premium | Deductible | Out-of-Pocket Max |
    |------|----------------|------------|-------------------|
    | Bronze | $150 | $3,000 | $6,500 |
    | Silver | $250 | $1,500 | $4,500 |
    | Gold | $350 | $500 | $2,500 |

    ### Dental and Vision

    - Dental: Basic preventive care is 100% covered
    - Vision: Annual eye exam and $150 frame allowance included

    ## Retirement Benefits

    ### 401(k) Plan

    - Company matches 100% of contributions up to 4% of salary
    - Vesting schedule: 100% after 2 years
    - Enrollment: First of the month following hire date

    ## Paid Time Off

    | Tenure | PTO Days |
    |--------|----------|
    | 0-2 years | 15 days |
    | 3-5 years | 20 days |
    | 5+ years | 25 days |

    ## Parental Leave

    - Birth parents: 16 weeks paid leave
    - Non-birth parents: 8 weeks paid leave

    ## Professional Development

    - $2,500 annual learning budget
    - Conference attendance encouraged
    - Internal training programs available

    ## Questions?

    Contact HR at hr@company.com or visit the HR office on the 3rd floor.
  MARKDOWN
  spaces: [ hr_space ],
  created_ago: 30.days
)

# =============================================================================
# Facilities Articles
# =============================================================================

articles << create_article(
  author: facilities_director,
  title: "Office Safety and Emergency Procedures",
  body: <<~MARKDOWN,
    ## Emergency Contacts

    - Security: x1234 or (555) 123-4567
    - Facilities: x5678 or facilities@company.com
    - Emergency Services: 911

    ## Fire Safety

    ### Fire Alarm Procedures

    1. When you hear the alarm, stop all work immediately
    2. Do NOT use elevators
    3. Proceed to the nearest stairwell
    4. Meet at your designated assembly point
    5. Do not re-enter the building until the all-clear is given

    ### Assembly Points

    - **Building A**: North parking lot
    - **Building B**: East lawn area
    - **Building C**: West visitor parking

    ### Fire Extinguisher Locations

    Fire extinguishers are located:
    - Near all stairwells
    - In kitchen/break room areas
    - Next to electrical panels

    ## Medical Emergencies

    1. Call 911 immediately for life-threatening emergencies
    2. Notify Security at x1234
    3. First aid kits are located in all break rooms
    4. AED devices are located near main elevators on each floor

    ## Severe Weather

    ### Tornado Warning

    Move to interior rooms away from windows:
    - Main floor: Conference rooms A, B, C
    - Second floor: Interior hallways
    - Avoid the cafeteria (large glass windows)

    ## Building Access

    - Badge required for entry at all times
    - Visitors must sign in at reception
    - Report lost badges to Security immediately

    ## Questions?

    Contact Facilities at facilities@company.com
  MARKDOWN
  spaces: [ facilities_space ],
  created_ago: 45.days
)

# =============================================================================
# Travel Articles
# =============================================================================

articles << create_article(
  author: travel_manager,
  title: "Business Travel Policy and Procedures",
  body: <<~MARKDOWN,
    ## Overview

    This policy applies to all business travel. Follow these guidelines to ensure smooth booking and reimbursement.

    ## Booking Travel

    ### Air Travel

    - Book through Concur at least 14 days in advance when possible
    - Economy class is standard for flights under 6 hours
    - Business class may be approved for international flights over 6 hours

    ### Hotels

    - Use preferred hotel chains (Marriott, Hilton, Hyatt)
    - Standard rate cap: $200/night domestic, $300/night international
    - Book through Concur for corporate rates

    ### Rental Cars

    - Use preferred vendors (Enterprise, Hertz, National)
    - Mid-size or smaller vehicles standard
    - Decline rental car insurance (covered by corporate policy)

    ## Per Diem Rates

    | Location | Breakfast | Lunch | Dinner | Total |
    |----------|-----------|-------|--------|-------|
    | Domestic | $15 | $20 | $35 | $70 |
    | International | $20 | $25 | $45 | $90 |

    ## Expense Reporting

    1. Submit expenses within 30 days of trip completion
    2. Attach itemized receipts for all expenses over $25
    3. Use Concur for all expense reports
    4. Manager approval required for expenses over $500

    ## Approval Requirements

    | Trip Cost | Approval Level |
    |-----------|---------------|
    | Under $2,000 | Direct Manager |
    | $2,000 - $5,000 | Director |
    | Over $5,000 | VP |

    ## Questions?

    Contact the Travel team at travel@company.com
  MARKDOWN
  spaces: [ travel_space ],
  created_ago: 40.days
)

# =============================================================================
# Finance Articles
# =============================================================================

articles << create_article(
  author: cfo,
  title: "Purchase Order and Invoice Processing Guide",
  body: <<~MARKDOWN,
    ## Overview

    This guide explains how to request purchases and process invoices.

    ## Purchase Orders

    ### When is a PO Required?

    - All purchases over $1,000
    - Recurring services and subscriptions
    - Software licenses
    - Equipment purchases

    ### How to Request a PO

    1. Log into the procurement portal
    2. Click "New Purchase Request"
    3. Fill in vendor details and line items
    4. Attach quotes (required for purchases over $5,000)
    5. Submit for approval

    ### Approval Thresholds

    | Amount | Approver |
    |--------|----------|
    | $0 - $5,000 | Manager |
    | $5,001 - $25,000 | Director |
    | $25,001 - $100,000 | VP |
    | Over $100,000 | CFO |

    ## Invoice Processing

    ### Submitting Invoices

    1. Send invoices to ap@company.com
    2. Reference PO number on all invoices
    3. Include vendor name and invoice number

    ### Payment Terms

    - Standard payment terms: Net 30
    - Early payment discount: 2% Net 10 (when offered)

    ### Invoice Status

    Check invoice status in the procurement portal under "My Invoices"

    ## Expense Reimbursement

    - Submit through Concur within 60 days
    - Receipts required for all expenses over $25
    - Direct deposit within 5 business days of approval

    ## Questions?

    Contact Accounts Payable at ap@company.com
  MARKDOWN
  spaces: [ finance_space ],
  created_ago: 35.days
)

# =============================================================================
# Product Management Articles
# =============================================================================

articles << create_article(
  author: vp_product,
  title: "Product Roadmap Process and Best Practices",
  body: <<~MARKDOWN,
    ## Introduction

    This document outlines our product roadmap process and how teams can contribute.

    ## Roadmap Structure

    ### Time Horizons

    - **Now** (0-3 months): Committed work, high confidence
    - **Next** (3-6 months): Planned work, medium confidence
    - **Later** (6-12 months): Exploratory, lower confidence

    ### Themes

    Each quarter focuses on 2-3 strategic themes aligned with company goals.

    ## Feature Request Process

    ### Submitting Ideas

    1. Create a feature request in ProductBoard
    2. Include: Problem statement, user impact, success metrics
    3. Link to customer feedback or research

    ### Prioritization Criteria

    We evaluate features using RICE:

    - **Reach**: How many users will this impact?
    - **Impact**: How much will it improve their experience?
    - **Confidence**: How sure are we about the estimates?
    - **Effort**: How much work is required?

    ## Sprint Planning

    ### Cadence

    - Sprint length: 2 weeks
    - Planning: Monday of sprint start
    - Demo: Friday of sprint end
    - Retro: Following Monday

    ### Capacity Planning

    - Reserve 20% for bugs and tech debt
    - 70% for roadmap features
    - 10% for experimentation

    ## Stakeholder Communication

    - Monthly roadmap review with leadership
    - Quarterly all-hands product update
    - Weekly release notes to all teams

    ## Questions?

    Reach out to the Product team in #product-questions
  MARKDOWN
  spaces: [ product_space, project_space ],
  created_ago: 25.days
)

# =============================================================================
# Project Management Articles
# =============================================================================

articles << create_article(
  author: pmo_director,
  title: "Agile Development Process Guide",
  body: <<~MARKDOWN,
    ## Overview

    This guide describes our Agile development process and ceremonies.

    ## Sprint Structure

    ### Sprint Length

    All teams use 2-week sprints starting on Monday.

    ### Ceremonies

    | Ceremony | Duration | Participants |
    |----------|----------|--------------|
    | Sprint Planning | 2 hours | Team + PO |
    | Daily Standup | 15 min | Team |
    | Sprint Review | 1 hour | Team + Stakeholders |
    | Retrospective | 1 hour | Team |

    ## Story Points

    ### Estimation Scale

    We use Fibonacci: 1, 2, 3, 5, 8, 13

    - **1 point**: Trivial change, < 2 hours
    - **3 points**: Small feature, 1-2 days
    - **5 points**: Medium feature, 3-5 days
    - **8 points**: Large feature, consider splitting
    - **13 points**: Too large, must split

    ## Definition of Done

    A story is "Done" when:

    - [ ] Code complete and reviewed
    - [ ] Tests written and passing
    - [ ] Documentation updated
    - [ ] Deployed to staging
    - [ ] PO acceptance

    ## Sprint Metrics

    ### Velocity

    Track team velocity over time. Use rolling average of last 3 sprints for planning.

    ### Burndown

    Update burndown daily. Investigate if significantly off-track by mid-sprint.

    ## Tools

    - **Jira**: Sprint boards and backlogs
    - **Confluence**: Documentation
    - **Slack**: Daily communication

    ## Questions?

    Contact the PMO at pmo@company.com
  MARKDOWN
  spaces: [ project_space ],
  created_ago: 22.days
)

puts "  Created #{articles.count} articles"
