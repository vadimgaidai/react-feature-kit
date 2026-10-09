#!/bin/bash
# Fixture for the `cross-cutting-feature` eval case: the shape of a real dashboard app —
# a folder-shaped context to mirror, a layout that mounts providers, a page with sections,
# a navigation config, a settings card, a long i18n catalogue, and a plan-approved library
# stubbed under node_modules with 750 lines of type declarations. Synthetic code, real shape.
set -eu

mkdir -p src/contexts/session-log src/layouts/dashboard src/pages/home/components \
         src/components/sidebar/components src/pages/settings/components/preferences \
         src/i18n/en node_modules/react-tour-lib/dist .planning/guided-tour

cat > package.json <<'EOF'
{
  "name": "eval-fixture",
  "private": true,
  "scripts": { "typecheck": "echo 'typecheck: ok'" },
  "dependencies": {
    "lucide-react": "^0.500.0",
    "react": "^19.2.0",
    "react-dom": "^19.2.0",
    "react-router": "^7.9.0",
    "react-tour-lib": "^1.4.0"
  }
}
EOF

cat > CLAUDE.md <<'EOF'
# Conventions

- TypeScript, React 19, react-router 7. Files and folders are kebab-case.
- Contexts live under `src/contexts/<name>/` as a folder (`config.ts`, `types.ts`, `storage.ts`, `provider.tsx`, `index.ts`); a trivial one may be a single `src/contexts/<name>.tsx`.
- Dashboard-scoped providers are mounted in `src/layouts/dashboard/index.tsx`, never in `App.tsx`.
- Handlers are named consts (`const handleClick = () => …`), never inline arrows in JSX.
- Every user-facing string is a key in `src/i18n/en/translation.json`, read through `useTranslation`.
- `pnpm typecheck` is the only check to run. `node_modules` is intentionally partial in this sandbox — install nothing.
EOF

cat > src/paths.ts <<'EOF'
export const paths = {
  homePage: "/",
  portfolioPage: "/portfolio",
  settingsPage: "/settings",
} as const
EOF

# --- the sibling: a folder-shaped context with its own localStorage helper ---
cat > src/contexts/session-log/config.ts <<'EOF'
export const sessionLogLimit = 50

export const sessionLogStorageKey = "session-log"
EOF

cat > src/contexts/session-log/types.ts <<'EOF'
export type SessionEventKind = "login" | "logout" | "export" | "error"

export interface ISessionEvent {
  id: string
  kind: SessionEventKind
  message: string
  createdAt: string
}
EOF

cat > src/contexts/session-log/storage.ts <<'EOF'
import { sessionLogLimit, sessionLogStorageKey } from "./config"
import type { ISessionEvent } from "./types"

export const readSessionLog = (): Array<ISessionEvent> => {
  try {
    const raw = localStorage.getItem(sessionLogStorageKey)
    return raw ? (JSON.parse(raw) as Array<ISessionEvent>) : []
  } catch {
    return []
  }
}

export const writeSessionLog = (events: Array<ISessionEvent>): void => {
  try {
    localStorage.setItem(sessionLogStorageKey, JSON.stringify(events.slice(-sessionLogLimit)))
  } catch {
    // storage unavailable — the log is best-effort
  }
}
EOF

cat > src/contexts/session-log/provider.tsx <<'EOF'
import { useCallback, useMemo, useState, type ReactNode } from "react"

import { SessionLogContext } from "./index"
import { readSessionLog, writeSessionLog } from "./storage"
import type { ISessionEvent, SessionEventKind } from "./types"

export const SessionLogProvider = ({ children }: { children: ReactNode }) => {
  const [events, setEvents] = useState<Array<ISessionEvent>>(() => readSessionLog())

  const log = useCallback((kind: SessionEventKind, message: string) => {
    setEvents((prev) => {
      const next = [...prev, { id: crypto.randomUUID(), kind, message, createdAt: new Date().toISOString() }]
      writeSessionLog(next)
      return next
    })
  }, [])

  const clear = useCallback(() => {
    setEvents([])
    writeSessionLog([])
  }, [])

  const value = useMemo(() => ({ events, log, clear }), [events, log, clear])

  return <SessionLogContext.Provider value={value}>{children}</SessionLogContext.Provider>
}
EOF

cat > src/contexts/session-log/index.ts <<'EOF'
import { createContext, useContext } from "react"

import type { ISessionEvent, SessionEventKind } from "./types"

interface ISessionLogContextType {
  events: Array<ISessionEvent>
  log: (kind: SessionEventKind, message: string) => void
  clear: () => void
}

export const SessionLogContext = createContext<ISessionLogContextType>({
  events: [],
  log: () => undefined,
  clear: () => undefined,
})

export const useSessionLog = (): ISessionLogContextType => useContext(SessionLogContext)

export { SessionLogProvider } from "./provider"
export type { ISessionEvent, SessionEventKind } from "./types"
EOF

# --- a single-file context, the simplest shape ---
cat > src/contexts/breadcrumb.tsx <<'EOF'
import { createContext, useContext, useState, type ReactNode } from "react"

interface IBreadcrumbContextType {
  title: string
  setTitle: (title: string) => void
}

export const BreadcrumbContext = createContext<IBreadcrumbContextType>({ title: "", setTitle: () => undefined })

export const useBreadcrumb = (): IBreadcrumbContextType => useContext(BreadcrumbContext)

export const BreadcrumbProvider = ({ children }: { children: ReactNode }) => {
  const [title, setTitle] = useState("")
  return <BreadcrumbContext.Provider value={{ title, setTitle }}>{children}</BreadcrumbContext.Provider>
}
EOF

# --- the layout that mounts dashboard-scoped providers ---
cat > src/layouts/dashboard/index.tsx <<'EOF'
import { Outlet } from "react-router"

import { Sidebar } from "@/components/sidebar"
import { BreadcrumbProvider } from "@/contexts/breadcrumb"
import { SessionLogProvider } from "@/contexts/session-log"

const DashboardLayout = () => (
  <SessionLogProvider>
    <BreadcrumbProvider>
      <div className="flex min-h-svh">
        <Sidebar />
        <main className="flex-1 p-6">
          <Outlet />
        </main>
      </div>
    </BreadcrumbProvider>
  </SessionLogProvider>
)

export default DashboardLayout
EOF

# --- the page with the sections a tour would anchor to ---
cat > src/pages/home/index.tsx <<'EOF'
import { useTranslation } from "react-i18next"

import { WeeklyChart } from "./components/weekly-chart"
import { NewsFeed } from "./components/news-feed"
import { Holdings } from "./components/holdings"
import { RecentActivity } from "./components/recent-activity"
import { SummaryTiles } from "./components/summary-tiles"

const HomePage = () => {
  const { t } = useTranslation()

  return (
    <div className="flex flex-col gap-6">
      <section aria-label={t("home.overview")}>
        <SummaryTiles />
      </section>
      <section aria-label={t("home.holdings")}>
        <Holdings />
      </section>
      <section aria-label={t("home.chart")}>
        <WeeklyChart />
      </section>
      <section aria-label={t("home.news")}>
        <NewsFeed />
      </section>
      <section aria-label={t("home.activity")}>
        <RecentActivity />
      </section>
    </div>
  )
}

export default HomePage
EOF

node -e '
  for (const c of ["weekly-chart", "news-feed", "holdings", "recent-activity", "summary-tiles"]) {
    const name = c.replace(/(^|-)([a-z])/g, (_, __, ch) => ch.toUpperCase())
    require("fs").writeFileSync("src/pages/home/components/" + c + ".tsx",
      "export const " + name + " = () => <div className=\"rounded-md border p-4\">" + name + "</div>\n")
  }
'

# --- navigation ---
cat > src/components/sidebar/types.ts <<'EOF'
import type { LucideIcon } from "lucide-react"

import type { paths } from "@/paths"

export interface INavigationItem {
  title: string
  url: (typeof paths)[keyof typeof paths]
  icon: LucideIcon
}

export type INavigationConfig = Array<INavigationItem>
EOF

cat > src/components/sidebar/config.ts <<'EOF'
import { Home, Settings, Wallet } from "lucide-react"

import { paths } from "@/paths"

import type { INavigationConfig } from "./types"

export const menuConfig: INavigationConfig = [
  { title: "nav.home", url: paths.homePage, icon: Home },
  { title: "nav.portfolio", url: paths.portfolioPage, icon: Wallet },
  { title: "nav.settings", url: paths.settingsPage, icon: Settings },
]
EOF

cat > src/components/sidebar/components/navigation.tsx <<'EOF'
import { NavLink } from "react-router"
import { useTranslation } from "react-i18next"

import { menuConfig } from "../config"

export const Navigation = () => {
  const { t } = useTranslation()

  return (
    <nav aria-label={t("nav.label")}>
      <ul className="flex flex-col gap-1">
        {menuConfig.map((item) => (
          <li key={item.url}>
            <NavLink to={item.url} className="flex items-center gap-2 rounded-md px-3 py-2 hover:bg-muted">
              <item.icon className="size-4" />
              <span>{t(item.title)}</span>
            </NavLink>
          </li>
        ))}
      </ul>
    </nav>
  )
}
EOF

cat > src/components/sidebar/components/sidebar.tsx <<'EOF'
import { Navigation } from "./navigation"

export const Sidebar = () => (
  <aside className="w-64 border-r p-4">
    <Navigation />
  </aside>
)
EOF

cat > src/components/sidebar/index.ts <<'EOF'
export { Sidebar } from "./components/sidebar"
export { menuConfig } from "./config"
export type { INavigationConfig, INavigationItem } from "./types"
EOF

# --- settings: card + row pattern ---
cat > src/pages/settings/components/preferences/settings-group.tsx <<'EOF'
import type { ReactNode } from "react"

export const SettingsGroup = ({ title, children }: { title: string; children: ReactNode }) => (
  <section className="rounded-md border">
    <h2 className="border-b px-4 py-3 text-sm font-medium">{title}</h2>
    <ul>{children}</ul>
  </section>
)
EOF

cat > src/pages/settings/components/preferences/settings-row.tsx <<'EOF'
import type { LucideIcon } from "lucide-react"

interface ISettingsRowProps {
  icon: LucideIcon
  text: string
  onClick: () => void
}

export const SettingsRow = ({ icon: Icon, text, onClick }: ISettingsRowProps) => (
  <li>
    <button type="button" onClick={onClick} className="flex w-full items-center gap-3 px-4 py-3 text-left hover:bg-muted">
      <Icon className="size-4 text-muted-foreground" />
      <span>{text}</span>
    </button>
  </li>
)
EOF

cat > src/pages/settings/components/preferences/index.tsx <<'EOF'
import { Languages, Palette } from "lucide-react"
import { useTranslation } from "react-i18next"

import { SettingsRow } from "./settings-row"
import { SettingsGroup } from "./settings-group"

export const Preferences = () => {
  const { t } = useTranslation()

  const handleLanguage = () => {
    // opens the language dialog
  }

  const handleTheme = () => {
    // toggles the theme
  }

  return (
    <SettingsGroup title={t("settings.application")}>
      <SettingsRow icon={Languages} text={t("settings.language")} onClick={handleLanguage} />
      <SettingsRow icon={Palette} text={t("settings.theme")} onClick={handleTheme} />
    </SettingsGroup>
  )
}
EOF

# --- a long i18n catalogue, the shape of a real one (~340 lines) ---
node -e '
  const t = {
    common: { save: "Save", cancel: "Cancel", close: "Close", back: "Back", next: "Next", skip: "Skip", finish: "Finish", loading: "Loading…" },
    nav: { label: "Main navigation", home: "Home", portfolio: "Portfolio", settings: "Settings" },
    home: { overview: "Overview", holdings: "Holdings", chart: "Weekly chart", news: "News", activity: "Recent activity" },
    settings: { application: "Application", language: "Language", theme: "Theme" },
    account: { login: "Sign in", logout: "Sign out", events: { login: "Signed in", logout: "Signed out", export: "Data exported", error: "Account error" } },
  }
  for (let i = 1; i <= 26; i++) {
    const ns = {}
    for (let j = 1; j <= 10; j++) ns["label_" + j] = "Legacy screen " + i + " label " + j
    t["legacy_screen_" + i] = ns
  }
  require("fs").writeFileSync("src/i18n/en/translation.json", JSON.stringify(t, null, 2) + "\n")
'

# --- the plan-approved library, stubbed: 750 lines of type declarations ---
cat > node_modules/react-tour-lib/package.json <<'EOF'
{ "name": "react-tour-lib", "version": "1.4.0", "main": "dist/index.js", "types": "dist/index.d.ts" }
EOF
echo 'module.exports = {}' > node_modules/react-tour-lib/dist/index.js
node -e '
  const head = [
    "import type { CSSProperties, ReactNode } from \"react\"",
    "",
    "export declare const STATUS: { readonly IDLE: \"idle\"; readonly RUNNING: \"running\"; readonly FINISHED: \"finished\"; readonly SKIPPED: \"skipped\" }",
    "export declare const EVENTS: { readonly STEP_AFTER: \"step:after\"; readonly TARGET_NOT_FOUND: \"error:target_not_found\"; readonly TOUR_END: \"tour:end\" }",
    "export declare const ACTIONS: { readonly NEXT: \"next\"; readonly PREV: \"prev\"; readonly SKIP: \"skip\"; readonly CLOSE: \"close\" }",
    "",
    "export interface Step {",
    "  target: string",
    "  content: ReactNode",
    "  title?: ReactNode",
    "  placement?: \"top\" | \"bottom\" | \"left\" | \"right\" | \"auto\"",
    "  disableBeacon?: boolean",
    "}",
    "",
    "export interface Locale {",
    "  back?: ReactNode",
    "  close?: ReactNode",
    "  last?: ReactNode",
    "  next?: ReactNode",
    "  skip?: ReactNode",
    "}",
    "",
    "export interface CallbackData {",
    "  action: (typeof ACTIONS)[keyof typeof ACTIONS]",
    "  index: number",
    "  status: (typeof STATUS)[keyof typeof STATUS]",
    "  type: (typeof EVENTS)[keyof typeof EVENTS]",
    "  step: Step",
    "}",
    "",
    "export interface Styles {",
    "  options?: { arrowColor?: string; backgroundColor?: string; primaryColor?: string; textColor?: string; zIndex?: number }",
    "  tooltip?: CSSProperties",
    "  buttonNext?: CSSProperties",
    "  buttonBack?: CSSProperties",
    "  buttonSkip?: CSSProperties",
    "}",
    "",
    "export interface TourProps {",
    "  steps: Array<Step>",
    "  run?: boolean",
    "  stepIndex?: number",
    "  continuous?: boolean",
    "  showSkipButton?: boolean",
    "  showProgress?: boolean",
    "  locale?: Locale",
    "  styles?: Styles",
    "  callback?: (data: CallbackData) => void",
    "}",
    "",
    "export default function Tour(props: TourProps): ReactNode",
    "",
  ]
  const filler = []
  for (let i = 0; i < 690; i++) filler.push("/** internal helper " + i + " — not part of the public API, kept for declaration compatibility */")
  require("fs").writeFileSync("node_modules/react-tour-lib/dist/index.d.ts", head.concat(filler).join("\n") + "\n")
'

# --- the plan, in the shape a real plan run writes ---
cat > .planning/guided-tour/PLAN.md <<'EOF'
# PLAN: guided-tour

**Shape:** feature

## Request

A guided tour of the Home page for first-time users: five steps over the Home sections, auto-starts once per browser, can be restarted from Settings.

## Modules

| # | Path | Role | Depends on |
|---|---|---|---|
| 1 | `src/contexts/guided-tour/` | Context + hook + provider + localStorage persistence — mirrors `src/contexts/session-log/` shape | — |
| 2 | `src/layouts/dashboard/index.tsx` | Mount `GuidedTourProvider` alongside the existing dashboard-scoped providers | 1 |
| 3 | `src/pages/home/components/guided-tour/` | The `<Tour>` instance + step config, rendered only on Home | 1 |
| 4 | `src/pages/home/index.tsx` | Wrap the five sections with `data-tour` anchors and render the tour | 3 |
| 5 | `src/components/sidebar/components/navigation.tsx` | `data-tour="nav-settings"` on the Settings item | 3 |
| 6 | `src/pages/settings/components/preferences/index.tsx` | A "Restart tour" `SettingsRow` row | 1 |

Build in this order.

## Conventions to follow

- `src/contexts/session-log/` — the reference for a folder-shaped context (`config.ts`, `types.ts`, `storage.ts`, `provider.tsx`, `index.ts`) with its own localStorage persistence helper.
- Dashboard-scoped providers (`SessionLogProvider`, `BreadcrumbProvider`) are mounted in `src/layouts/dashboard/index.tsx`, not in `App.tsx` — `GuidedTourProvider` joins them there.
- `src/pages/settings/components/preferences/index.tsx` — existing `SettingsGroup` / `SettingsRow` (`settings-row.tsx`) pattern for a new settings row; mirror a `SettingsRow` (icon + text + `onClick`) rather than inventing a new row shape.
- Handlers are named consts, no inline arrows (`CLAUDE.md`).
- Every tour string is an i18n key under `tour.*` in `src/i18n/en/translation.json`.

## Dependencies

`react-tour-lib` 1.4.0 — chosen in planning, **already installed** (`node_modules/react-tour-lib`, types in `dist/index.d.ts`). Add nothing else.

## Contract

none — no API in this unit of work.

## Design

none.

## Per module

### `src/contexts/guided-tour/`

- **config.ts**: `tourStorageKey = "guided-tour-completed"`.
- **types.ts**: `ITourState { isRunning: boolean; stepIndex: number }`.
- **storage.ts**: `readTourCompleted(): boolean` / `writeTourCompleted(): void` — try/catch around `localStorage`, mirrors `session-log/storage.ts` exactly (silent catch).
- **provider.tsx**: on mount, `isRunning = !readTourCompleted()`, gated on `location.pathname === paths.homePage`. `restartTour()` sets `isRunning = true` regardless of the stored flag and does not clear it. `handleTourCallback` reacts to `STATUS.FINISHED` / `STATUS.SKIPPED` → `writeTourCompleted()` + `isRunning = false`.
- **index.ts**: barrel — the context, `useGuidedTour`, `GuidedTourProvider`, the types.

### `src/pages/home/components/guided-tour/`

- **steps.ts**: five `Step`s targeting `[data-tour="overview"]`, `holdings`, `chart`, `news`, `activity`; content from `t("tour.steps.*")`.
- **guided-tour.tsx**: `<Tour steps={steps} run={isRunning} continuous showSkipButton locale={…} callback={handleTourCallback} />`, locale strings from `tour.buttons.*`.

### Edits

- `src/pages/home/index.tsx`: `data-tour` on the five sections; render `<GuidedTour />`.
- `src/components/sidebar/components/navigation.tsx`: `data-tour="nav-settings"` on the Settings item.
- `src/pages/settings/components/preferences/index.tsx`: a `SettingsRow` "Restart tour" (`Compass` icon) calling `restartTour` from `useGuidedTour`.

## UI States

Tour running / not running. No loading or error states.

## Roles & Permissions

none

## i18n

`tour.steps.overview|holdings|chart|news|activity`, `tour.restart`, `tour.buttons.back|next|skip|finish`.

## Acceptance Criteria

- [ ] `src/contexts/guided-tour/` mirrors the sibling's folder shape and barrel.
- [ ] `GuidedTourProvider` is mounted in `src/layouts/dashboard/index.tsx`.
- [ ] The five Home sections carry `data-tour` anchors and the tour has five steps.
- [ ] Settings has a "Restart tour" row built from `SettingsRow`.
- [ ] All tour strings live in `translation.json` under `tour.*`.

## Out of scope

Tours on other pages; server-side persistence.

## Open questions

None.
EOF
