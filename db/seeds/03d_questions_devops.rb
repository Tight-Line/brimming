# frozen_string_literal: true

# =============================================================================
# Questions and Answers - DevOps Space
# =============================================================================
puts "Creating DevOps questions..."

devops_space = Space.find_by!(slug: "devops")

# OOMKilled question
create_qa(
  space: devops_space,
  author: SEED_INTERMEDIATES["fullstack.carol@example.com"],
  title: "Kubernetes pod keeps getting OOMKilled - how to debug memory issues?",
  body: <<~BODY,
    My Rails app pod keeps getting OOMKilled in Kubernetes. I've set memory limits but it keeps happening:

    ```yaml
    resources:
      requests:
        memory: "512Mi"
      limits:
        memory: "1Gi"
    ```

    The app works fine locally with similar memory usage. How do I debug what's consuming all the memory?

    Logs from `kubectl describe pod`:
    ```
    State:          Waiting
      Reason:       CrashLoopBackOff
    Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    137
    ```
  BODY
  answers: [
    {
      author: SEED_EXPERTS["principal.eng.tom@example.com"],
      body: <<~ANSWER,
        OOMKilled issues can be tricky. Here's a systematic debugging approach:

        **1. Check actual memory usage:**
        ```bash
        kubectl top pod <pod-name>
        kubectl exec -it <pod-name> -- cat /sys/fs/cgroup/memory/memory.usage_in_bytes
        ```

        **2. Enable memory profiling in Rails:**
        ```ruby
        # Gemfile
        gem 'memory_profiler'
        gem 'derailed_benchmarks'

        # Run locally:
        bundle exec derailed bundle:mem
        ```

        **3. Common culprits for Rails:**
        - **Puma workers**: Each worker consumes memory. If you have 4 workers × 300MB = 1.2GB
        - **Asset precompilation**: Can spike memory during startup
        - **Memory leaks**: Often from string interpolation in loops or unclosed connections

        **4. Quick fixes to try:**
        ```yaml
        env:
          - name: MALLOC_ARENA_MAX
            value: "2"  # Reduces glibc memory fragmentation
          - name: RAILS_MAX_THREADS
            value: "5"
          - name: WEB_CONCURRENCY
            value: "2"  # Reduce Puma workers
        ```

        **5. Use jemalloc:**
        ```dockerfile
        RUN apt-get install -y libjemalloc2
        ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2
        ```

        Start with `MALLOC_ARENA_MAX=2` - it's a quick win that often reduces memory by 30-50%.
      ANSWER
      votes: 28,
      correct: true
    }
  ],
  created_ago: 10.days
)

# K8s vs Docker Compose question (no accepted answer)
create_qa(
  space: devops_space,
  author: SEED_INTERMEDIATES["dev.marcus@example.com"],
  title: "Kubernetes vs Docker Compose for small team - is K8s overkill?",
  body: <<~BODY,
    We're a team of 5 developers running 3 microservices. Currently using Docker Compose in production on a single server.

    Getting pressure to move to Kubernetes for "scalability" but I'm skeptical.

    Is K8s worth the complexity for a small team? What's the break-even point?
  BODY
  answers: [
    {
      author: SEED_EXPERTS["principal.eng.tom@example.com"],
      body: <<~ANSWER,
        **Kubernetes is overkill for you.** Here's the reality check:

        **K8s complexity:**
        - 2-3 months to learn properly
        - YAML hell (100s of lines for simple apps)
        - Networking is dark magic
        - Debugging is 10x harder
        - Need dedicated DevOps or pay for managed K8s

        **What you actually need for 3 services:**
        ```yaml
        # docker-compose.prod.yml
        services:
          app:
            image: myapp:latest
            deploy:
              replicas: 2
              update_config:
                parallelism: 1
                delay: 10s
          worker:
            image: myworker:latest
        ```

        Docker Swarm (built into Docker) gives you:
        - Service discovery
        - Rolling deploys
        - Basic load balancing
        - Secrets management

        Move to K8s when: 20+ services, multiple teams, need advanced networking, or compliance requires it.
      ANSWER
      votes: 38,
      correct: false
    },
    {
      author: SEED_EXPERTS["senior.rachel@example.com"],
      body: <<~ANSWER,
        Disagree with the "K8s is overkill" crowd. **Managed Kubernetes is very accessible:**

        ```bash
        # GKE Autopilot - fully managed
        gcloud container clusters create-auto my-cluster

        # Deploy your app
        kubectl apply -f deployment.yaml
        ```

        **Why K8s even for small teams:**
        - Industry standard (transferable skills)
        - Helm charts = instant PostgreSQL, Redis, etc.
        - Auto-scaling, self-healing built-in
        - Cost optimization (node autoscaling)
        - Better security defaults

        **The real question:** Can you afford a $200-400/month managed K8s cluster? If yes, it's worth it for the operational benefits.

        Don't run K8s yourself though. GKE Autopilot, EKS Fargate, or DigitalOcean Kubernetes.
      ANSWER
      votes: 31,
      correct: false
    }
  ],
  created_ago: 5.days
)

puts "  Created DevOps questions"
