---
title: Web Workers in Next.js 15 with Comlink
date: 2025-04-17
categories:
  - Next.js
  - Comlink
---

Running heavy computations or background tasks directly on the main thread can lead to a sluggish user interface 🐌. Web Workers offer a solution by allowing you to run scripts in background threads, keeping your UI responsive. However, communicating with Web Workers traditionally involves a lot of boilerplate code using `postMessage` and event listeners.

[Comlink](https://github.com/GoogleChromeLabs/comlink) is a tiny library by the Google Chrome team that simplifies Web Worker communication, making it feel like you're interacting with local objects or functions.

![Image](https://private-user-images.githubusercontent.com/1064036/434752415-3f41194c-9155-4ee5-bf99-fcf8a6561acc.jpg?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3NDQ4ODU0NTMsIm5iZiI6MTc0NDg4NTE1MywicGF0aCI6Ii8xMDY0MDM2LzQzNDc1MjQxNS0zZjQxMTk0Yy05MTU1LTRlZTUtYmY5OS1mY2Y4YTY1NjFhY2MuanBnP1gtQW16LUFsZ29yaXRobT1BV1M0LUhNQUMtU0hBMjU2JlgtQW16LUNyZWRlbnRpYWw9QUtJQVZDT0RZTFNBNTNQUUs0WkElMkYyMDI1MDQxNyUyRnVzLWVhc3QtMSUyRnMzJTJGYXdzNF9yZXF1ZXN0JlgtQW16LURhdGU9MjAyNTA0MTdUMTAxOTEzWiZYLUFtei1FeHBpcmVzPTMwMCZYLUFtei1TaWduYXR1cmU9MDU0OGJhYmM3ZjgyOTM3NzhjMWQ5ZTIzMDMwZDIzNTNhNjE2YmVlNjBjZmYzMTY4MzNiNzNjMWNkNzI5ODAxNyZYLUFtei1TaWduZWRIZWFkZXJzPWhvc3QifQ.hKewRs4x6wIlv9HkjaEXVN0ocgsxbsJPOr6bvvjx7Xc)

In this post, I'll explore how to integrate Web Workers into a Next.js 15 application using Comlink, based on [this example repository](https://github.com/subwaymatch/nextjs-comlink-examples). I'll cover:

1.  What Comlink is and why it's useful.
2.  The overhead of using vanilla Web Workers (with TypeScript examples).
3.  Why we initialize Comlink workers inside `useEffect()` in Next.js client components.
4.  How to manage worker instances: Singleton vs. Non-Singleton patterns.

## 🤔 What is Comlink?

[Comlink](https://github.com/GoogleChromeLabs/comlink) is a JavaScript library that abstracts away the complexities of `postMessage` communication between the main thread and Web Workers. It allows you to expose functions or even entire classes from your worker file and call them directly from your main thread code as if they were local asynchronous functions or objects. This makes the developer experience significantly smoother, essentially providing an RPC (Remote Procedure Call) interface for your workers.

## 😫 The Pain of Vanilla Web Workers (TypeScript Examples)

Without a library like Comlink, interacting with a Web Worker looks something like this, with TypeScript adding type safety:

### 📜 Shared Types - e.g., `types/worker-messages.ts`)

```typescript
// Define message structures for type safety
export interface WorkerCommand {
  command: "multiply";
  value: number;
  // Add other commands as needed, possibly using a union type for 'command'
}

export interface WorkerResponse {
  result?: number; // Optional in case of errors
  error?: string;
  // Add other response fields as needed
}
```

### 📜 Main Thread (`page.tsx` - Vanilla Example):

```typescript
import type { WorkerCommand, WorkerResponse } from "@/types/worker-messages";

// Create the worker using the modern pattern
// Assumes 'vanilla.worker.ts' exists and the build process handles it
const myWorker: Worker = new Worker(
  new URL("@/workers/vanilla.worker.ts", import.meta.url),
  {
    type: "module",
  }
);

// Send data to the worker
const commandMessage: WorkerCommand = { command: "multiply", value: 5 };
myWorker.postMessage(commandMessage);

// Listen for messages FROM the worker
myWorker.onmessage = (e: MessageEvent<WorkerResponse>) => {
  console.log("Message received from worker:", e.data);
  if (e.data?.error) {
    console.error(`Worker reported error: ${e.data.error}`);
  } else if (typeof e.data?.result === "number") {
    // Process the result
    console.log(`Result is: ${e.data.result}`);
  } else {
    console.warn("Received unexpected data format:", e.data);
  }
  // Need logic here to handle different types of responses if applicable
};

// Handle errors (e.g., script loading errors)
myWorker.onerror = (error: Event) => {
  // ErrorEvent provides more details
  console.error("Worker error:", error);
};

// Remember to terminate the worker when no longer needed
// myWorker.terminate();
```

### 📜 Worker Thread (`/workers/vanilla.worker.ts`):

```typescript
import type { WorkerCommand, WorkerResponse } from "@/types/worker-messages";

console.log("Vanilla worker script loading...");

// Listen for messages FROM the main thread using addEventListener
addEventListener("message", (event: MessageEvent<WorkerCommand>) => {
  console.log("Message received from main script:", event.data);
  const { command, value } = event.data;

  try {
    if (command === "multiply" && typeof value === "number") {
      const result = value * 2;
      const response: WorkerResponse = { result: result };
      postMessage(response); // Send response back
    } else {
      console.warn(
        "Unknown command or invalid value received:",
        command,
        value
      );
      const errorResponse: WorkerResponse = {
        error: "Unknown command or invalid value",
      };
      postMessage(errorResponse); // Report error back
    }
  } catch (err) {
    console.error("Error processing message in worker:", err);
    const errorResponse: WorkerResponse = {
      error: err instanceof Error ? err.message : "An unknown error occurred",
    };
    postMessage(errorResponse); // Report processing error back
  }
});

// Listen for unhandled errors within the worker itself
addEventListener("error", (event) => {
  console.error("Unhandled error in worker:", event.error || event);
  // Optional: report error back to main thread
  // postMessage({ error: `Worker error: ${event.message}` });
});

console.log("Vanilla worker script loaded and listeners attached.");
```

As you can see, even with TypeScript, this involves:

- Manually defining message interfaces (WorkerCommand, WorkerResponse).
- Manually sending messages using postMessage.
- Manually listening for messages using onmessage or addEventListener on both sides.
- Manually checking command types and validating data within the handlers.
- Handling potential errors explicitly in message data or via onerror.
- Terminating workers manually.
- This gets cumbersome quickly, especially when dealing with multiple functions or complex interactions.

## ✨ Enter Comlink: Making Workers Easy

Comlink simplifies this significantly.

### 📜 Worker (`/workers/functions.worker.ts`):

```typescript
import * as Comlink from "comlink";

async function multiplyByTwo(value: number) {
  return value * 2;
}

// Just expose the functions/objects you want the main thread to access
Comlink.expose({
  multiplyByTwo,
});
```

### 📜 Main Thread (`/app/basic/page.tsx` - Comlink Example):

```typescript
"use client"; // Important for using hooks and browser APIs

import { useEffect, useRef } from "react";
import * as Comlink from "comlink";

// Define the type for type safety (optional but recommended)
type WorkerApi = {
  multiplyByTwo: (value: number) => Promise<number>;
};

// Inside your component...
const workerRef = useRef<Comlink.Remote<WorkerApi> | null>(null);
const workerInstance = useRef<Worker | null>(null); // Keep ref to worker for termination

useEffect(() => {
  // Create the actual Worker instance
  workerInstance.current = new Worker(
    new URL("@/workers/functions.worker.ts", import.meta.url),
    { type: "module" } // Needed for TypeScript/ES Modules in workers
  );

  // Wrap the worker with Comlink
  workerRef.current = Comlink.wrap<WorkerApi>(workerInstance.current);

  // Cleanup function to terminate the worker when the component unmounts
  return () => {
    workerInstance.current?.terminate();
    console.log("Basic worker terminated");
  };
}, []); // Empty dependency array ensures this runs once on mount

const handleClick = async () => {
  if (workerRef.current) {
    try {
      // Call the worker function directly!
      const result = await workerRef.current.multiplyByTwo(5);
      alert(`5 multiplied by 2 is ${result}`);
    } catch (error) {
      console.error("Error calling worker function:", error);
      alert("Worker communication error.");
    }
  }
};

// ... TSX ...
```

Look how clean that is! `Comlink.expose` in the worker and `Comlink.wrap` on the main thread handle all the `postMessage` boilerplate and data marshalling for you. Error handling also becomes more natural with `async`/`await` `try...catch`.

The `/app/basic/page.tsx` example demonstrates the simplest use case. It creates a worker from `/workers/functions.worker.ts`, wraps it with Comlink, and calls the `multiplyByTwo` function exposed by the worker. Straightforward and effective for offloading simple tasks.

## 🚀 Setting up Comlink in Next.js (Client Components)

You might notice the Comlink setup happens inside a useEffect hook in the example (`/app/basic/page.tsx`). Why?

1. **Web Workers are a Browser API**: The `Worker` constructor (`new Worker(...)`) is part of the browser's `window` object. It doesn't exist in the Node.js environment where Next.js performs Server-Side Rendering (SSR) or builds the application.
2. **Client Components**: By marking the component with `"use client"`, we tell Next.js that this component relies on browser-specific APIs and should only run on the client side.
3. **`useEffect` Hook**: Using `useEffect` with an empty dependency array (`[]`) ensures that the code inside it runs only after the component has mounted on the client-side browser. This guarantees that the `window` object and the `Worker` API are available.
   Attempting to create a Worker outside useEffect in a client component (or directly in a server component) would lead to errors during SSR or build because Worker is not defined.

The `new URL("@/workers/...", import.meta.url)` pattern is required for JavaScript bundling. It tells the bundler (like Webpack used by Next.js) where to find the worker file relative to the current module and how to bundle it correctly so the browser can load it.

## 🔄 Understanding Worker Instances: Singleton vs. Non-Singleton

Now, let's look at the more complex examples involving the Calculator class in `/workers/class-instance.worker.ts`.

### 📜 Worker (`/workers/class-instance.worker.ts`):

```typescript
import * as Comlink from "comlink";

export class Calculator {
  private total: number;

  constructor(initialValue: number = 0) {
    console.log(
      `Calculator instantiated in worker thread with initial value: ${initialValue}`
    );
    this.total = initialValue;
  }

  add(value: number): void {
    console.log(`Worker adding ${value} to ${this.total}`);
    this.total += value;
  }

  subtract(value: number): void {
    console.log(`Worker subtracting ${value} from ${this.total}`);
    this.total -= value;
  }

  getTotal(): number {
    console.log(`Worker returning total: ${this.total}`);
    return this.total;
  }
}

// Create ONE instance of Calculator within this worker script's global scope
const instance = new Calculator();
console.log("Worker: Calculator instance created and exposing.");

// Expose that single instance
Comlink.expose(instance);
```

### 🧐 Why Two Comlink.wrap Calls Don't Share State (Non-Singleton)

Consider the `/app/non-singleton/page.tsx` example. It creates two separate worker instances:

### 📜 `/app/non-singleton/page.tsx`

```typescript
// In useEffect...
const worker1 = new Worker(
  new URL("@/workers/class-instance.worker.ts", import.meta.url),
  { type: "module" }
);
firstWorkerRef.current = Comlink.wrap(worker1);
// Keep reference for termination
firstWorkerInstance.current = worker1;

const worker2 = new Worker(
  new URL("@/workers/class-instance.worker.ts", import.meta.url),
  { type: "module" }
);
secondWorkerRef.current = Comlink.wrap(worker2);
// Keep reference for termination
secondWorkerInstance.current = worker2;

// Remember to add termination logic in the useEffect cleanup function!
```

**Crucially, calling new `Worker(...)` _always_ creates a new, independent background thread and execution context.** Even though both calls point to the _same_ worker file (`class-instance.worker.ts`), they each spin up a separate instance of that script.

Inside each of those separate worker threads, the line `const instance = new Calculator();` runs independently, creating two distinct `Calculator` objects in memory, each within its own worker thread's global scope.

Therefore, when you use `Comlink.wrap` on `worker1` and `worker2`, you get proxies to two different `Calculator` instances living in two different threads. Interacting with `firstWorkerRef.current` modifies the state of the calculator in the first worker thread, while `secondWorkerRef.current` modifies the state in the second, completely separate thread. They don't share state. This is the Non-Singleton approach, useful when you need isolated stateful workers.

### 🤝 What is a Singleton Pattern?

A **Singleton** is a design pattern that restricts the instantiation of a class or resource to a single object or instance. Essentially, it ensures that there's only one instance of a particular resource (like our worker connection) available throughout the application, providing a global point of access to it.

### 💡 Implementing a Singleton Worker with Comlink

The `/app/singleton/page.tsx` example demonstrates how to achieve shared state using the singleton pattern. The magic happens in `/lib/singletonCalculator.ts`:

### 📜 `/lib/singletonCalculator.ts`

```typescript
import * as Comlink from "comlink";
// Make sure the path is correct based on your project structure
import type { Calculator } from "@/workers/class-instance.worker";

let worker: Worker | null = null;
let calculatorProxy: Comlink.Remote<Calculator> | null = null;

export async function getSingletonCalculator(): Promise<
  Comlink.Remote<Calculator>
> {
  // Only create the worker and proxy if they don't exist yet
  if (!calculatorProxy) {
    console.log("Creating Singleton Worker and Proxy..."); // Log for clarity
    worker = new Worker(
      // Adjust the path if 'lib' and 'workers' are at different levels
      new URL("../workers/class-instance.worker.ts", import.meta.url),
      { type: "module" }
    );

    // Optional: Add error handling for worker creation/loading
    worker.onerror = (event) => {
      console.error("Singleton worker error:", event);
      // Potentially nullify proxy/worker so retry is possible?
      calculatorProxy = null;
      worker = null;
    };

    calculatorProxy = Comlink.wrap<Calculator>(worker);
    // You might want to await a confirmation from the worker
    // or simply assume it's ready after wrapping.
  }

  // Add a check in case worker creation failed asynchronously
  if (!calculatorProxy) {
    throw new Error("Failed to initialize singleton calculator worker.");
  }

  // Always return the same proxy instance
  return calculatorProxy;
}

// Optional: Function to terminate the singleton worker if needed application-wide
export function terminateSingletonCalculator() {
  if (worker) {
    console.log("Terminating Singleton Worker...");
    worker.terminate();
    worker = null;
    calculatorProxy = null;
  }
}
```

This utility function ensures that the `new Worker(...)` and `Comlink.wrap(...)` calls happen only once. Subsequent calls to `getSingletonCalculator()` return the same `calculatorProxy` instance that was created the first time (unless an error occurred).

### 📜 `/app/singleton/page.tsx`

```typescript
useEffect(() => {
  let instance1: Comlink.Remote<Calculator> | null = null;
  let instance2: Comlink.Remote<Calculator> | null = null;

  const initializeWorkers = async () => {
    try {
      instance1 = await getSingletonCalculator();
      firstWorkerRef.current = instance1;
      // Fetch initial state after getting the instance
      const total1 = await instance1.getTotal();
      setFirstTotal(total1);

      instance2 = await getSingletonCalculator(); // Gets the SAME instance
      secondWorkerRef.current = instance2;
      // Fetch initial state (should be same as total1 if no ops happened)
      const total2 = await instance2.getTotal();
      setSecondTotal(total2);
    } catch (error) {
      console.error("Failed to initialize singleton workers:", error);
      // Handle error state in UI
    }
  };

  initializeWorkers();

  // Note: Terminating the singleton worker is tricky from a single component's
  // useEffect cleanup, as other components might still need it.
  // Termination should likely be handled at a higher level or manually triggered.
  // return () => { terminateSingletonCalculator(); } // Avoid this unless sure
}, []);
```

Both `firstWorkerRef` and `secondWorkerRef` end up holding a reference to the _exact same Comlink proxy_. This proxy communicates with the single underlying Web Worker thread and the single `Calculator` instance running within it. Therefore, any operation performed via `firstWorkerRef` (e.g., `add(2)`) modifies the state of the one calculator instance, and that change is immediately reflected when accessing the state via `secondWorkerRef` (e.g., calling `getTotal()`), and vice-versa.

## 👋 Closing Thoughts

Comlink significantly improves my experience when working with Web Workers in Typescript and Next.js applications. It removes the boilerplate of manual message passing, allowing me to focus on the logic of your background tasks.

Understanding the difference between creating multiple worker instances (non-singleton) and managing a single shared instance (singleton) is key to architecting your application correctly, depending on whether you need isolated background tasks or a shared background service with shared state.

🔗 Check out the full code examples: https://github.com/subwaymatch/nextjs-comlink-examples
