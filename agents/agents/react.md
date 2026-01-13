# React Development

## Module Organization

- Always prefer named exports over default exports
- Can combine multiple components in one file if they're not reused elsewhere
- Example:
  ```javascript
  export function Button({ onClick, children }) {
    return <button onClick={onClick}>{children}</button>;
  }

  export function IconButton({ icon, onClick }) {
    return <button onClick={onClick}>{icon}</button>;
  }
  ```

## useEffect Best Practices (2026)

- Only use `useEffect` for synchronizing with external systems (APIs, DOM, third-party libraries)
- Do NOT use `useEffect` for:
  - Derived state calculations (calculate during render instead)
  - Updating state based on other state changes (use event handlers)
  - Transforming data for rendering (use regular variables)

**When to use useEffect:**
```javascript
// ✅ Good: Synchronizing with external system
useEffect(() => {
  const connection = createConnection(serverUrl, roomId);
  connection.connect();
  return () => {
    connection.disconnect(); // Always cleanup
  };
}, [serverUrl, roomId]); // Include ALL dependencies
```

**When NOT to use useEffect:**
```javascript
// ❌ Bad: Derived state
const [fullName, setFullName] = useState('');
useEffect(() => {
  setFullName(firstName + ' ' + lastName);
}, [firstName, lastName]);

// ✅ Good: Calculate during render
const fullName = firstName + ' ' + lastName;
```

**Critical useEffect Rules:**

1. **Always specify dependencies correctly** - Trust the linter, include ALL reactive values
2. **Always provide cleanup functions** - Return a cleanup function for subscriptions, connections, timers
3. **Handle race conditions for async operations** - Use the `ignore` flag pattern:
   ```javascript
   useEffect(() => {
     let ignore = false;

     async function fetchData() {
       const result = await fetch(url);
       if (!ignore) {
         setData(result);
       }
     }

     fetchData();
     return () => { ignore = true; };
   }, [url]);
   ```

## Available Skills

When working with React, consider these specialized skills:
- `npx skills find react` - Search for React-related skills
- Notable skills: `react-flow-architecture`, `tanstack-query`, `next-cache-components`
