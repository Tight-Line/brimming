# Contributing to Brimming

Thank you for your interest in contributing to Brimming! This document provides guidelines and instructions for contributing.

## Development Setup

### Prerequisites

- Docker and Docker Compose
- Make

### Getting Started

```bash
# Clone the repository
git clone https://github.com/your-org/brimming.git
cd brimming

# Set up the development environment
make setup

# Start all services
make up

# Run tests to verify everything works
make test
```

## Development Workflow

### Running the Application

```bash
make up        # Start all services in the background
make server    # Start Rails server (accessible at localhost:3000)
make console   # Open Rails console
make shell     # Open bash shell in dev container
```

### Database Operations

```bash
make db-migrate   # Run pending migrations
make db-rollback  # Rollback last migration
make db-reset     # Drop, create, migrate, and seed database
make db-seed      # Load seed data
```

### Testing

We require 100% test coverage for all new code.

```bash
make test          # Run all tests with coverage
make test-models   # Run model specs only
make test-requests # Run request specs only
make test-jobs     # Run job specs only
```

### Code Quality

```bash
make lint       # Run RuboCop linter
make lint-fix   # Run RuboCop with auto-fix
make security   # Run security scans
```

## Pull Request Process

1. **Fork the repository** and create your branch from `main`.

2. **Write tests** for any new functionality. We require 100% test coverage.

3. **Follow code style** - run `make lint` before committing.

4. **Update documentation** if you're changing functionality.

5. **Write clear commit messages** that explain the "why" behind changes.

6. **Open a pull request** with a clear description of the changes.

### PR Checklist

- [ ] Tests pass (`make test`)
- [ ] Linting passes (`make lint`)
- [ ] Security scans pass (`make security`)
- [ ] Documentation updated if needed
- [ ] Helm chart updated if adding new workloads

## Code Style

- Follow the [Ruby Style Guide](https://rubystyle.guide/)
- Use `frozen_string_literal: true` in all Ruby files
- Prefer `let` and `let!` over instance variables in specs
- Write request specs instead of controller specs
- Use service objects for complex business logic

## Helm Chart Changes

If your changes affect the application architecture (new services, ports, etc.):

1. Update the Helm chart in `helm/brimming/`
2. Add corresponding tests in `helm/brimming/tests/`
3. Run `make helm-lint` and `make helm-test`

## Reporting Issues

When reporting issues, please include:

- Ruby version
- Rails version
- Steps to reproduce
- Expected vs actual behavior
- Relevant logs or error messages

## Questions?

Feel free to open an issue for questions or discussions.
