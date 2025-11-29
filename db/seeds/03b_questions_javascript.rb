# frozen_string_literal: true

# =============================================================================
# Questions and Answers - JavaScript Space
# =============================================================================
puts "Creating JavaScript questions..."

js_space = Space.find_by!(slug: "javascript")

# Expert JS question
create_qa(
  space: js_space,
  author: SEED_EXPERTS["prof.aisha.patel@example.com"],
  title: "Understanding JavaScript event loop: Microtasks vs Macrotasks execution order",
  body: <<~BODY,
    I'm trying to understand the exact execution order of the JavaScript event loop, particularly the relationship between microtasks and macrotasks.

    Consider this code:

    ```javascript
    console.log('1');

    setTimeout(() => console.log('2'), 0);

    Promise.resolve().then(() => {
      console.log('3');
      setTimeout(() => console.log('4'), 0);
    }).then(() => console.log('5'));

    queueMicrotask(() => console.log('6'));

    console.log('7');
    ```

    I expected the output to be `1, 7, 3, 6, 5, 2, 4` but I'm seeing different results in different environments.

    Can someone explain:
    1. The exact execution order and why?
    2. How do `queueMicrotask`, `Promise.then`, and `MutationObserver` differ in timing?
    3. Are there any browser-specific differences I should be aware of?
  BODY
  answers: [
    {
      author: SEED_EXPERTS["tech.lead.omar@example.com"],
      body: <<~ANSWER,
        Great question! Let me break down the event loop execution model:

        **Correct Output: `1, 7, 3, 6, 5, 2, 4`**

        **Execution Phases:**

        1. **Synchronous code runs first** (call stack)
           - `console.log('1')` → prints `1`
           - `setTimeout` schedules callback as macrotask
           - `Promise.resolve().then()` schedules callback as microtask
           - `queueMicrotask` schedules callback as microtask
           - `console.log('7')` → prints `7`

        2. **All microtasks run** (before any macrotask)
           - First `.then()` runs → prints `3`, schedules setTimeout
           - `queueMicrotask` callback runs → prints `6`
           - Second `.then()` runs → prints `5`

        3. **First macrotask runs**
           - Original `setTimeout` → prints `2`

        4. **Microtask queue checked** (empty)

        5. **Next macrotask runs**
           - `setTimeout` from inside Promise → prints `4`

        **Key Insight:**
        ```
        Call Stack → Microtask Queue (ALL of them) → ONE Macrotask → Repeat
        ```

        **Microtask sources (same queue):**
        - `Promise.then/catch/finally`
        - `queueMicrotask()`
        - `MutationObserver`

        **Macrotask sources:**
        - `setTimeout/setInterval`
        - `setImmediate` (Node.js)
        - I/O operations
        - UI rendering (browsers)

        **Browser Differences:**
        Modern browsers are consistent, but older browsers (pre-2018) had quirks with Promise timing. Always test in your target environments.
      ANSWER
      votes: 35,
      correct: true
    }
  ],
  created_ago: 20.days
)

# Intermediate JS question - Debounce
create_qa(
  space: js_space,
  author: SEED_INTERMEDIATES["frontend.emma@example.com"],
  title: "How to properly debounce API calls in React with hooks?",
  body: <<~BODY,
    I'm building a search component that makes API calls as the user types. I want to debounce these calls to avoid overwhelming the server.

    Here's my current implementation:

    ```jsx
    function SearchComponent() {
      const [query, setQuery] = useState('');
      const [results, setResults] = useState([]);

      useEffect(() => {
        const timeoutId = setTimeout(() => {
          if (query) {
            fetchResults(query).then(setResults);
          }
        }, 300);

        return () => clearTimeout(timeoutId);
      }, [query]);

      return (
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
      );
    }
    ```

    This works, but I'm wondering:
    1. Is this the correct pattern for debouncing in React?
    2. Should I use `useMemo` or `useCallback` somewhere?
    3. How do I handle the case where a slow request returns after a faster one?
  BODY
  answers: [
    {
      author: SEED_EXPERTS["senior.rachel@example.com"],
      body: <<~ANSWER,
        Your basic approach is correct! Let me address each concern:

        **1. Improved Debounce Pattern**
        Your implementation is fine, but here's a more robust version:

        ```jsx
        function useDebounce(value, delay) {
          const [debouncedValue, setDebouncedValue] = useState(value);

          useEffect(() => {
            const handler = setTimeout(() => {
              setDebouncedValue(value);
            }, delay);

            return () => clearTimeout(handler);
          }, [value, delay]);

          return debouncedValue;
        }

        function SearchComponent() {
          const [query, setQuery] = useState('');
          const [results, setResults] = useState([]);
          const debouncedQuery = useDebounce(query, 300);

          useEffect(() => {
            if (debouncedQuery) {
              fetchResults(debouncedQuery).then(setResults);
            }
          }, [debouncedQuery]);

          return <input value={query} onChange={(e) => setQuery(e.target.value)} />;
        }
        ```

        **2. No need for useMemo/useCallback here**
        The custom hook encapsulates the logic cleanly.

        **3. Handling Race Conditions (Critical!)**
        Use an AbortController or a flag:

        ```jsx
        useEffect(() => {
          let cancelled = false;

          if (debouncedQuery) {
            fetchResults(debouncedQuery).then(data => {
              if (!cancelled) setResults(data);
            });
          }

          return () => { cancelled = true; };
        }, [debouncedQuery]);
        ```

        Or with AbortController:
        ```jsx
        useEffect(() => {
          const controller = new AbortController();

          if (debouncedQuery) {
            fetchResults(debouncedQuery, { signal: controller.signal })
              .then(setResults)
              .catch(e => {
                if (e.name !== 'AbortError') throw e;
              });
          }

          return () => controller.abort();
        }, [debouncedQuery]);
        ```
      ANSWER
      votes: 28,
      correct: true
    }
  ],
  created_ago: 5.days
)

# Newbie JS question - undefined
create_qa(
  space: js_space,
  author: SEED_NEWBIES["beginner.jack@example.com"],
  title: "why does my variable say undefined?????",
  body: <<~BODY,
    so i have this code and it keeps saying undefined and i dont know why

    ```javascript
    function getData() {
      fetch('https://api.example.com/data')
        .then(response => response.json())
        .then(data => {
          return data;
        });
    }

    const result = getData();
    console.log(result);  // undefined!!!!
    ```

    i clearly return the data so why isnt it working?!?!
  BODY
  answers: [
    {
      author: SEED_INTERMEDIATES["dev.ashley@example.com"],
      body: <<~ANSWER,
        This is one of the most common JavaScript gotchas! The issue is that `fetch` is **asynchronous**.

        When you call `getData()`, it starts the fetch but immediately returns `undefined` (because the function doesn't have a `return` statement at its top level).

        Here's how to fix it:

        **Option 1: Return the Promise**
        ```javascript
        function getData() {
          return fetch('https://api.example.com/data')  // Add return here!
            .then(response => response.json());
        }

        getData().then(result => {
          console.log(result);  // Now it works!
        });
        ```

        **Option 2: Use async/await (recommended)**
        ```javascript
        async function getData() {
          const response = await fetch('https://api.example.com/data');
          return response.json();
        }

        // Using it:
        const result = await getData();
        console.log(result);
        ```

        The key concept: `fetch` returns a Promise, which represents a value that will be available *in the future*. You can't treat it like synchronous code.
      ANSWER
      votes: 15,
      correct: true
    },
    {
      author: SEED_NEWBIES["learning.kate@example.com"],
      body: <<~ANSWER,
        omg i had this exact problem last week!! async stuff is so confusing at first but once you get it it makes sense. the answer above helped me too
      ANSWER
      votes: 3
    }
  ],
  created_ago: 1.day
)

# State management question (SCENARIO 2: No accepted answer)
create_qa(
  space: js_space,
  author: SEED_INTERMEDIATES["web.julia@example.com"],
  title: "Best state management solution for React in 2024?",
  body: <<~BODY,
    Starting a new React project and need to decide on state management. Options I'm considering:

    - Redux Toolkit
    - Zustand
    - Jotai
    - React Query + Context
    - Just useState/useContext

    What's the current consensus? We'll have ~50 components, some complex forms, and API data fetching.
  BODY
  answers: [
    {
      author: SEED_EXPERTS["tech.lead.omar@example.com"],
      body: <<~ANSWER,
        For your use case, I'd recommend **React Query + Zustand**:

        **React Query** for server state:
        ```jsx
        const { data, isLoading } = useQuery({
          queryKey: ['users'],
          queryFn: fetchUsers
        });
        ```

        **Zustand** for client state:
        ```jsx
        const useStore = create((set) => ({
          filters: {},
          setFilter: (key, value) => set((state) => ({
            filters: { ...state.filters, [key]: value }
          }))
        }));
        ```

        This combo is lightweight, has great DX, and separates concerns cleanly. Redux is overkill for most apps in 2024.
      ANSWER
      votes: 45,
      correct: false
    },
    {
      author: SEED_EXPERTS["senior.rachel@example.com"],
      body: <<~ANSWER,
        Controversial take: **just use React's built-in state**.

        With React 18's automatic batching and useSyncExternalStore, you often don't need external state management anymore.

        ```jsx
        // Context for auth/theme (rarely changes)
        const AuthContext = createContext();

        // Local state for forms
        const [formData, setFormData] = useState({});

        // React Query for server data
        const { data } = useQuery(['posts'], fetchPosts);
        ```

        Only add Zustand/Redux when you *actually* hit prop drilling issues. YAGNI applies to state management too.
      ANSWER
      votes: 32,
      correct: false
    },
    {
      author: SEED_INTERMEDIATES["backend.kevin@example.com"],
      body: <<~ANSWER,
        We switched from Redux to Zustand last year and it was the best decision. Redux has too much boilerplate:

        ```jsx
        // Zustand - simple and clean
        const useCart = create((set) => ({
          items: [],
          addItem: (item) => set((s) => ({ items: [...s.items, item] })),
          clearCart: () => set({ items: [] })
        }));

        // Usage - no Provider needed!
        function Cart() {
          const items = useCart((s) => s.items);
          return <div>{items.length} items</div>;
        }
        ```

        Zero boilerplate, great TypeScript support, and tiny bundle size.
      ANSWER
      votes: 21,
      correct: false
    }
  ],
  created_ago: 3.days
)

# Newbie array loop question
create_qa(
  space: js_space,
  author: SEED_NEWBIES["student.nathan@example.com"],
  title: "How to loop through an array in JavaScript?",
  body: <<~BODY,
    how do i loop through an array? i tried this but it doesnt work

    ```javascript
    for (let i = 0; i < arr; i++) {
      console.log(arr[i]);
    }
    ```

    it says arr is not a number or something??
  BODY
  answers: [
    {
      author: SEED_NEWBIES["bootcamp.olivia@example.com"],
      body: <<~ANSWER,
        you need arr.length not arr!!

        ```javascript
        for (let i = 0; i < arr.length; i++) {
          console.log(arr[i]);
        }
        ```

        i made the same mistake lol
      ANSWER
      votes: 3,
      correct: true
    },
    {
      author: SEED_INTERMEDIATES["dev.ashley@example.com"],
      body: <<~ANSWER,
        The fix above is correct. Here are all the ways to loop arrays in modern JS:

        ```javascript
        const arr = [1, 2, 3];

        // Classic for loop
        for (let i = 0; i < arr.length; i++) {
          console.log(arr[i]);
        }

        // for...of (recommended for most cases)
        for (const item of arr) {
          console.log(item);
        }

        // forEach
        arr.forEach(item => console.log(item));

        // map (when you need to transform)
        const doubled = arr.map(x => x * 2);
        ```

        Use `for...of` unless you specifically need the index.
      ANSWER
      votes: 12,
      correct: false
    }
  ],
  created_ago: 1.day
)

puts "  Created JavaScript questions"
