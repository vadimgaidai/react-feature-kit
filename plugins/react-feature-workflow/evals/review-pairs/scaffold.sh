#!/bin/bash
# Fixture for the `review-pairs` eval case. Runs in the empty workspace before the prompt
# (`--scaffold`). Four pairs, each a defect and its legitimate twin in separate files:
#   react            task-board sorts props in place   / task-list sorts a local copy
#   ui-conventions   task-panel part holds own state   / filter-panel part reads Root's context
#   react-hook-form  edit-task resets on every refetch / edit-note resets on entity change only
#   tanstack-query   task infinite query on list key   / note infinite(filters) in the factory
set -eu

mkdir -p src/entities/task/api src/entities/task/model \
         src/entities/note/api src/entities/note/model \
         src/entities/project/api src/entities/project/model \
         src/widgets/task-board/ui src/widgets/task-list/ui \
         src/widgets/task-panel/ui src/widgets/filter-panel/ui \
         src/features/edit-task/ui src/features/edit-note/ui \
         .planning/tasks

cat > package.json <<'EOF'
{
  "name": "eval-fixture",
  "private": true,
  "scripts": { "typecheck": "echo 'typecheck: ok'" }
}
EOF

cat > .planning/tasks/PLAN.md <<'EOF'
# PLAN: tasks

**Shape:** feature

## Conventions to follow
- `src/entities/project/` — the sibling the entities mirror: folder shape, key factory.
EOF

cat > src/entities/project/model/types.ts <<'EOF'
export interface Project {
  id: string
  name: string
}
EOF
cat > src/entities/project/api/project.queries.ts <<'EOF'
import { queryOptions } from "@tanstack/react-query"
import type { Project } from "../model/types"

export const projectKeys = {
  all: ["project"] as const,
  byId: (id: string) => [...projectKeys.all, id] as const,
}

export const projectQueries = {
  byId: (id: string) =>
    queryOptions({ queryKey: projectKeys.byId(id), queryFn: () => fetchProjectUniqueToken(id) }),
}

function fetchProjectUniqueToken(id: string): Promise<Project> {
  return fetch(`/projects/${id}`).then((r) => r.json())
}
EOF
cat > src/entities/project/index.ts <<'EOF'
export type { Project } from "./model/types"
export { projectKeys, projectQueries } from "./api/project.queries"
EOF

cat > src/entities/task/model/types.ts <<'EOF'
export interface Task {
  id: string
  title: string
  priority: number
}

export interface TaskFilters {
  status?: "open" | "done"
}
EOF
cat > src/entities/note/model/types.ts <<'EOF'
export interface Note {
  id: string
  body: string
}

export interface NoteFilters {
  pinned?: boolean
}
EOF

git init -q
git config user.email eval@example.com
git config user.name Eval
git symbolic-ref HEAD refs/heads/main
git add -A
git commit -qm "baseline: plan, untouched sibling, task and note types"

git checkout -qb feature/tasks

cat > src/entities/task/api/task.queries.ts <<'EOF'
import { infiniteQueryOptions, queryOptions } from "@tanstack/react-query"
import type { Task, TaskFilters } from "../model/types"

export const taskKeys = {
  all: ["task"] as const,
  lists: () => [...taskKeys.all, "list"] as const,
  list: (filters: TaskFilters) => [...taskKeys.all, "list", filters] as const,
}

export const taskQueries = {
  list: (filters: TaskFilters) =>
    queryOptions({ queryKey: taskKeys.list(filters), queryFn: () => getTasks(filters) }),
  infinite: (filters: TaskFilters) =>
    infiniteQueryOptions({
      queryKey: taskKeys.list(filters),
      queryFn: ({ pageParam }) => getTasks({ ...filters }, pageParam),
      initialPageParam: null as string | null,
      getNextPageParam: (lastPage) => lastPage.nextCursor ?? undefined,
    }),
}

function getTasks(filters: TaskFilters, cursor?: string | null): Promise<{ items: Task[]; nextCursor: string | null }> {
  return fetch(`/tasks?status=${filters.status ?? ""}&cursor=${cursor ?? ""}`).then((r) => r.json())
}
EOF
cat > src/entities/task/index.ts <<'EOF'
export type { Task, TaskFilters } from "./model/types"
export { taskKeys, taskQueries } from "./api/task.queries"
EOF

cat > src/entities/note/api/note.queries.ts <<'EOF'
import { infiniteQueryOptions, queryOptions } from "@tanstack/react-query"
import type { Note, NoteFilters } from "../model/types"

export const noteKeys = {
  all: ["note"] as const,
  lists: () => [...noteKeys.all, "list"] as const,
  list: (filters: NoteFilters) => [...noteKeys.all, "list", filters] as const,
  infinite: (filters: NoteFilters) => [...noteKeys.all, "infinite", filters] as const,
}

export const noteQueries = {
  list: (filters: NoteFilters) =>
    queryOptions({ queryKey: noteKeys.list(filters), queryFn: () => getNotes(filters) }),
  infinite: (filters: NoteFilters) =>
    infiniteQueryOptions({
      queryKey: noteKeys.infinite(filters),
      queryFn: ({ pageParam }) => getNotes(filters, pageParam),
      initialPageParam: null as string | null,
      getNextPageParam: (lastPage) => lastPage.nextCursor ?? undefined,
    }),
}

function getNotes(filters: NoteFilters, cursor?: string | null): Promise<{ items: Note[]; nextCursor: string | null }> {
  return fetch(`/notes?pinned=${filters.pinned ?? ""}&cursor=${cursor ?? ""}`).then((r) => r.json())
}
EOF
cat > src/entities/note/index.ts <<'EOF'
export type { Note, NoteFilters } from "./model/types"
export { noteKeys, noteQueries } from "./api/note.queries"
EOF

cat > src/widgets/task-board/ui/task-board.tsx <<'EOF'
import type { Task } from "@/entities/task"

interface TaskBoardProps {
  tasks: Task[]
}

export function TaskBoard({ tasks }: TaskBoardProps) {
  const ordered = tasks.sort((a, b) => a.priority - b.priority)

  return (
    <ul>
      {ordered.map((task) => (
        <li key={task.id}>{task.title}</li>
      ))}
    </ul>
  )
}
EOF
cat > src/widgets/task-board/index.ts <<'EOF'
export { TaskBoard } from "./ui/task-board"
EOF

cat > src/widgets/task-list/ui/task-list.tsx <<'EOF'
import type { Task } from "@/entities/task"

interface TaskListProps {
  tasks: Task[]
}

export function TaskList({ tasks }: TaskListProps) {
  const ordered = [...tasks].sort((a, b) => a.priority - b.priority)

  return (
    <ul>
      {ordered.map((task) => (
        <li key={task.id}>{task.title}</li>
      ))}
    </ul>
  )
}
EOF
cat > src/widgets/task-list/index.ts <<'EOF'
export { TaskList } from "./ui/task-list"
EOF

cat > src/widgets/task-panel/ui/task-panel.tsx <<'EOF'
import { createContext, useContext, useState, type ReactNode } from "react"

interface TaskPanelContextValue {
  isOpen: boolean
  toggle: () => void
}

const TaskPanelContext = createContext<TaskPanelContextValue | null>(null)

function TaskPanelRoot({ children }: { children: ReactNode }) {
  const [isOpen, setIsOpen] = useState(false)
  return <TaskPanelContext value={{ isOpen, toggle: () => setIsOpen((open) => !open) }}>{children}</TaskPanelContext>
}

function TaskPanelTrigger({ children }: { children: ReactNode }) {
  const [isOpen, setIsOpen] = useState(false)
  return (
    <button type="button" aria-expanded={isOpen} onClick={() => setIsOpen((open) => !open)}>
      {children}
    </button>
  )
}

function TaskPanelContent({ children }: { children: ReactNode }) {
  const context = useContext(TaskPanelContext)
  return <div hidden={!context?.isOpen}>{children}</div>
}

export const TaskPanel = { Root: TaskPanelRoot, Trigger: TaskPanelTrigger, Content: TaskPanelContent }
EOF
cat > src/widgets/task-panel/index.ts <<'EOF'
export { TaskPanel } from "./ui/task-panel"
EOF

cat > src/widgets/filter-panel/ui/filter-panel.tsx <<'EOF'
import { createContext, useContext, useState, type ReactNode } from "react"

interface FilterPanelContextValue {
  isOpen: boolean
  toggle: () => void
}

const FilterPanelContext = createContext<FilterPanelContextValue | null>(null)

function useFilterPanel() {
  const context = useContext(FilterPanelContext)
  if (!context) {
    throw new Error("FilterPanel parts must be rendered inside FilterPanel.Root")
  }
  return context
}

function FilterPanelRoot({ children }: { children: ReactNode }) {
  const [isOpen, setIsOpen] = useState(false)
  return <FilterPanelContext value={{ isOpen, toggle: () => setIsOpen((open) => !open) }}>{children}</FilterPanelContext>
}

function FilterPanelTrigger({ children }: { children: ReactNode }) {
  const { isOpen, toggle } = useFilterPanel()
  return (
    <button type="button" aria-expanded={isOpen} onClick={toggle}>
      {children}
    </button>
  )
}

function FilterPanelContent({ children }: { children: ReactNode }) {
  const { isOpen } = useFilterPanel()
  return <div hidden={!isOpen}>{children}</div>
}

export const FilterPanel = { Root: FilterPanelRoot, Trigger: FilterPanelTrigger, Content: FilterPanelContent }
EOF
cat > src/widgets/filter-panel/index.ts <<'EOF'
export { FilterPanel } from "./ui/filter-panel"
EOF

cat > src/features/edit-task/ui/edit-task-form.tsx <<'EOF'
import { useEffect } from "react"
import { useForm } from "react-hook-form"
import type { Task } from "@/entities/task"

interface EditTaskFormProps {
  task: Task
  onSave: (values: { title: string }) => void
}

export function EditTaskForm({ task, onSave }: EditTaskFormProps) {
  const form = useForm<{ title: string }>({ defaultValues: { title: task.title } })

  useEffect(() => {
    form.reset({ title: task.title })
  }, [task, form])

  return (
    <form onSubmit={form.handleSubmit(onSave)}>
      <input {...form.register("title")} />
      <button type="submit">Save</button>
    </form>
  )
}
EOF
cat > src/features/edit-task/index.ts <<'EOF'
export { EditTaskForm } from "./ui/edit-task-form"
EOF

cat > src/features/edit-note/ui/edit-note-form.tsx <<'EOF'
import { useForm } from "react-hook-form"
import type { Note } from "@/entities/note"

interface EditNoteFormProps {
  note: Note
  onSave: (values: { body: string }) => void
}

function EditNoteFields({ note, onSave }: EditNoteFormProps) {
  const form = useForm<{ body: string }>({
    values: { body: note.body },
    resetOptions: { keepDirtyValues: true },
  })

  return (
    <form onSubmit={form.handleSubmit(onSave)}>
      <textarea {...form.register("body")} />
      <button type="submit">Save</button>
    </form>
  )
}

export function EditNoteForm({ note, onSave }: EditNoteFormProps) {
  return <EditNoteFields key={note.id} note={note} onSave={onSave} />
}
EOF
cat > src/features/edit-note/index.ts <<'EOF'
export { EditNoteForm } from "./ui/edit-note-form"
EOF

git add -A
git commit -qm "feat(tasks): boards, panels, edit forms, infinite lists"
