# TypeScript Development

**Philosophy: Let TypeScript Infer, But Stay Strongly Typed**

Leverage TypeScript's type inference while maintaining a strongly typed codebase. Avoid both over-annotation and under-typing.

## Type Inference Best Practices

✅ **DO let TypeScript infer:**

```typescript
// ✅ Variable initialization - inference works perfectly
let name = "Alice"; // Type: string
let count = 42; // Type: number
let items = [1, 2, 3]; // Type: number[]

// ✅ Function return types - inference from return statements
function add(a: number, b: number) {
  return a + b; // Inferred: number
}

// ✅ Const assertions for literal types
const config = {
  apiUrl: "https://api.example.com",
  timeout: 5000,
} as const; // Type: { readonly apiUrl: "https://api.example.com"; readonly timeout: 5000 }

const colors = ["red", "green", "blue"] as const; // Type: readonly ["red", "green", "blue"]
```

❌ **DO explicitly annotate:**

```typescript
// ✅ Function parameters - always annotate
function greet(name: string, age: number) {
  return `Hello, ${name}!`;
}

// ✅ Public API boundaries and exported functions
export function processData(input: DataInput): ProcessedResult {
  // Explicit return type for API stability
  return transformData(input);
}

// ✅ Complex types that need documentation
interface UserPreferences {
  theme: "light" | "dark";
  notifications: boolean;
  language: string;
}

// ✅ When inference would be too wide
const colors: ("red" | "green" | "blue")[] = ["red", "green"];
// Without annotation, would be string[]
```

## Strong Typing Patterns

```typescript
// ✅ Use discriminated unions for type safety
type Result<T> =
  | { success: true; data: T }
  | { success: false; error: string };

function handleResult<T>(result: Result<T>) {
  if (result.success) {
    console.log(result.data); // TypeScript knows data exists
  } else {
    console.log(result.error); // TypeScript knows error exists
  }
}

// ✅ Leverage const assertions for immutability
function getRoutes() {
  return [
    { path: "/home", component: "Home" },
    { path: "/about", component: "About" },
  ] as const; // Readonly, literal types preserved
}

// ✅ Use utility types for transformations
type User = {
  id: string;
  name: string;
  email: string;
  password: string;
};

type PublicUser = Omit<User, "password">; // Remove sensitive fields
type UserUpdate = Partial<User>; // All fields optional
type ReadonlyUser = Readonly<User>; // All fields readonly
```

## Critical Rules

1. **Never use `any`** - Use `unknown` instead, then narrow the type
   ```typescript
   // ❌ Bad
   function process(data: any) { }

   // ✅ Good
   function process(data: unknown) {
     if (typeof data === "string") {
       // Type narrowed to string
       console.log(data.toUpperCase());
     }
   }
   ```

2. **Enable strict mode** - Always use `strict: true` in tsconfig.json
   ```json
   {
     "compilerOptions": {
       "strict": true,
       "noUncheckedIndexedAccess": true,
       "exactOptionalPropertyTypes": true
     }
   }
   ```

3. **Use type narrowing instead of type assertions**
   ```typescript
   // ❌ Avoid type assertions
   const value = data as SomeType;

   // ✅ Use type guards
   function isSomeType(data: unknown): data is SomeType {
     return typeof data === "object" && data !== null && "prop" in data;
   }

   if (isSomeType(data)) {
     // data is now SomeType
   }
   ```

4. **Prefer `const` over `let` with `as const` for literal types**
   ```typescript
   // ❌ Type widens to string
   let status = "pending";

   // ✅ Type is "pending"
   const status = "pending";

   // ✅ Readonly array with literal types
   const statuses = ["pending", "active", "completed"] as const;
   type Status = typeof statuses[number]; // "pending" | "active" | "completed"
   ```

5. **Annotate function parameters, let return types infer (except for public APIs)**
   ```typescript
   // ✅ Good - parameters typed, return inferred
   function calculateTotal(items: CartItem[], taxRate: number) {
     return items.reduce((sum, item) => sum + item.price, 0) * (1 + taxRate);
   }

   // ✅ Good - public API with explicit return type
   export function createUser(data: UserInput): Promise<User> {
     return api.post("/users", data);
   }
   ```
