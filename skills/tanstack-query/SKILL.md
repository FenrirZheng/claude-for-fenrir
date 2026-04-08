---
name: tanstack-query
description: Use when implementing API data fetching in React. Triggers - adding CRUD operations, fetching lists, caching server state, handling loading/error states, invalidating stale data
---

# TanStack Query Usage

## Overview

TanStack Query manages server state in React. Core principle: **server state is not client state** - it needs caching, background updates, and stale-while-revalidate patterns.

## When to Use

**Use when:**
- Fetching data from API endpoints
- CRUD operations (create, read, update, delete)
- Need loading/error states
- Need automatic cache invalidation
- Need background refetching

**Don't use for:**
- Client-only state (use useState/useReducer)
- Form state (use react-hook-form)
- Global UI state (use context/zustand)

## Installation & Setup

```bash
npm install @tanstack/react-query
```

**main.tsx setup:**
```tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5 minutes
      retry: 1,
    },
  },
});

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <App />
    </QueryClientProvider>
  </StrictMode>,
);
```

## Query Key Factory Pattern

Create a centralized key factory per domain:

```ts
// src/api/whitelist/keys.ts
export const whitelistKeys = {
  all: ['whitelist'] as const,
  lists: () => [...whitelistKeys.all, 'list'] as const,
  list: (filters: WhitelistFilters) => [...whitelistKeys.lists(), filters] as const,
  details: () => [...whitelistKeys.all, 'detail'] as const,
  detail: (id: string) => [...whitelistKeys.details(), id] as const,
};
```

**Usage:**
```ts
// Invalidate all whitelist queries
queryClient.invalidateQueries({ queryKey: whitelistKeys.all });

// Invalidate only lists
queryClient.invalidateQueries({ queryKey: whitelistKeys.lists() });

// Fetch specific detail
useQuery({ queryKey: whitelistKeys.detail(id), ... });
```

## API Client with Error Handling

**IMPORTANT:** HTTP status is always 200. Check response body for errors.

```ts
// src/api/client.ts
export interface ApiResponse<T> {
  code: number;      // Business code: 0 = success, others = error
  message: string;
  data: T;
}

export class ApiError extends Error {
  constructor(public code: number, message: string) {
    super(message);
    this.name = 'ApiError';
  }
}

export async function apiClient<T>(
  endpoint: string,
  options?: RequestInit
): Promise<T> {
  const response = await fetch(`/api${endpoint}`, {
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
    ...options,
  });

  const result: ApiResponse<T> = await response.json();

  // HTTP is always 200, check body for errors
  if (result.code !== 0) {
    throw new ApiError(result.code, result.message);
  }

  return result.data;
}
```

## Query Pattern (Fetching Data)

```ts
// src/api/whitelist/queries.ts
import { useQuery } from '@tanstack/react-query';
import { apiClient } from '../client';
import { whitelistKeys } from './keys';
import type { WhitelistItem } from './types';

export function useWhitelistList() {
  return useQuery({
    queryKey: whitelistKeys.lists(),
    queryFn: () => apiClient<WhitelistItem[]>('/whitelist'),
  });
}

export function useWhitelistDetail(id: string) {
  return useQuery({
    queryKey: whitelistKeys.detail(id),
    queryFn: () => apiClient<WhitelistItem>(`/whitelist/${id}`),
    enabled: !!id, // Only fetch when id exists
  });
}
```

**Usage in component:**
```tsx
function WhitelistPage() {
  const { data: list, isLoading, error } = useWhitelistList();

  if (isLoading) return <Loading />;
  if (error) return <Error message={error.message} />;

  return <WhitelistTable data={list ?? []} />;
}
```

## Mutation Pattern (Create/Update/Delete)

```ts
// src/api/whitelist/mutations.ts
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient } from '../client';
import { whitelistKeys } from './keys';
import type { WhitelistItem, CreateWhitelistInput } from './types';

export function useCreateWhitelist() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: CreateWhitelistInput) =>
      apiClient<WhitelistItem>('/whitelist', {
        method: 'POST',
        body: JSON.stringify(input),
      }),
    onSuccess: () => {
      // Invalidate list to refetch
      queryClient.invalidateQueries({ queryKey: whitelistKeys.lists() });
    },
  });
}

export function useUpdateWhitelist() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, ...input }: UpdateWhitelistInput) =>
      apiClient<WhitelistItem>(`/whitelist/${id}`, {
        method: 'PUT',
        body: JSON.stringify(input),
      }),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: whitelistKeys.lists() });
      queryClient.invalidateQueries({ queryKey: whitelistKeys.detail(variables.id) });
    },
  });
}

export function useDeleteWhitelist() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) =>
      apiClient<void>(`/whitelist/${id}`, { method: 'DELETE' }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: whitelistKeys.lists() });
    },
  });
}
```

**Usage in component:**
```tsx
function WhitelistPage() {
  const { data: list } = useWhitelistList();
  const createMutation = useCreateWhitelist();
  const deleteMutation = useDeleteWhitelist();

  const handleAdd = (input: CreateWhitelistInput) => {
    createMutation.mutate(input, {
      onSuccess: () => toast.success('新增成功'),
      onError: (err) => toast.error(err.message),
    });
  };

  const handleDelete = (id: string) => {
    if (!confirm('確定要刪除此項目嗎？')) return;
    deleteMutation.mutate(id);
  };

  return (
    <>
      <AddButton onClick={() => handleAdd(...)} disabled={createMutation.isPending} />
      <WhitelistTable data={list ?? []} onDelete={handleDelete} />
    </>
  );
}
```

## Types Definition

```ts
// src/api/whitelist/types.ts
export interface WhitelistItem {
  id: string;
  ip: string;
  description: string;
  createdAt: string;
}

export interface WhitelistFilters {
  page?: number;
  pageSize?: number;
  search?: string;
}

export interface CreateWhitelistInput {
  ip: string;
  description?: string;
}

export interface UpdateWhitelistInput extends CreateWhitelistInput {
  id: string;
}

// Paginated response
export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
}
```

## Pagination Pattern

```ts
// src/api/whitelist/queries.ts
export function useWhitelistListPaginated(filters: WhitelistFilters) {
  return useQuery({
    queryKey: whitelistKeys.list(filters),
    queryFn: () => apiClient<PaginatedResponse<WhitelistItem>>(
      `/whitelist?page=${filters.page ?? 1}&pageSize=${filters.pageSize ?? 20}`
    ),
  });
}
```

**Usage:**
```tsx
function WhitelistPage() {
  const [page, setPage] = useState(1);
  const { data, isLoading } = useWhitelistListPaginated({ page, pageSize: 20 });

  return (
    <>
      <WhitelistTable data={data?.items ?? []} />
      <Pagination
        current={page}
        total={data?.total ?? 0}
        pageSize={20}
        onChange={setPage}
      />
    </>
  );
}
```

## Optimistic Updates (Optional)

For instant UI feedback before server confirms:

```ts
export function useDeleteWhitelistOptimistic() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) =>
      apiClient<void>(`/whitelist/${id}`, { method: 'DELETE' }),
    onMutate: async (id) => {
      // Cancel outgoing refetches
      await queryClient.cancelQueries({ queryKey: whitelistKeys.lists() });

      // Snapshot previous value
      const previous = queryClient.getQueryData(whitelistKeys.lists());

      // Optimistically remove item
      queryClient.setQueryData(whitelistKeys.lists(), (old: WhitelistItem[] | undefined) =>
        old?.filter(item => item.id !== id)
      );

      return { previous };
    },
    onError: (_err, _id, context) => {
      // Rollback on error
      queryClient.setQueryData(whitelistKeys.lists(), context?.previous);
    },
    onSettled: () => {
      // Refetch to ensure sync
      queryClient.invalidateQueries({ queryKey: whitelistKeys.lists() });
    },
  });
}
```

## File Organization

```
src/api/
  client.ts              # apiClient with error handling
  whitelist/
    keys.ts              # Query key factory
    types.ts             # TypeScript types
    queries.ts           # useQuery hooks
    mutations.ts         # useMutation hooks
    index.ts             # Re-exports
```

**index.ts example:**
```ts
// src/api/whitelist/index.ts
export * from './keys';
export * from './types';
export * from './queries';
export * from './mutations';
```

## Quick Reference

| Operation | Hook | Invalidate |
|-----------|------|------------|
| Fetch list | `useQuery` + `queryKey: keys.lists()` | - |
| Fetch detail | `useQuery` + `queryKey: keys.detail(id)` | - |
| Create | `useMutation` | `keys.lists()` |
| Update | `useMutation` | `keys.lists()` + `keys.detail(id)` |
| Delete | `useMutation` | `keys.lists()` |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Inline query keys | Use key factory for consistency |
| Forgetting `enabled` option | Add `enabled: !!id` for conditional queries |
| Not invalidating after mutation | Always invalidate related queries in `onSuccess` |
| Handling HTTP status only | Check `response.code` in body (HTTP always 200) |
| Mixing server/client state | Use TanStack Query for server state only |
