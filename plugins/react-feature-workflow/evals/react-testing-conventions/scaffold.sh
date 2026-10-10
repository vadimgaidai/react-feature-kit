#!/bin/bash
# Fixture for the `react-testing-conventions` eval case. Runs in the empty workspace before
# the prompt (`--scaffold`).
set -eu

mkdir -p src/features/online-indicator

cat > package.json <<'EOF'
{
  "name": "eval-fixture",
  "private": true,
  "devDependencies": { "vitest": "^2.0.0", "@testing-library/react": "^16.0.0" },
  "scripts": { "typecheck": "echo 'typecheck: ok'", "test": "echo 'test: ok'" }
}
EOF

cat > src/features/online-indicator/online-indicator.tsx <<'EOF'
import { useEffect, useState } from "react"

export const OnlineIndicator = () => {
  const [online, setOnline] = useState(navigator.onLine)

  useEffect(() => {
    const on = () => setOnline(true)
    const off = () => setOnline(false)
    window.addEventListener("online", on)
    window.addEventListener("offline", off)
    return () => {
      window.removeEventListener("online", on)
      window.removeEventListener("offline", off)
    }
  }, [])

  return <span role="status">{online ? "Online" : "Offline"}</span>
}
EOF

git init -q
git config user.email eval@example.com
git config user.name Eval
git symbolic-ref HEAD refs/heads/main
git add -A
git commit -qm "baseline: online indicator component"

git checkout -qb feature/online-indicator-test

cat > src/features/online-indicator/online-indicator.test.tsx <<'EOF'
import { render, screen } from "@testing-library/react"
import { vi, describe, expect, test } from "vitest"

import { OnlineIndicator } from "./online-indicator"

vi.mock("./online-indicator", async () => {
  const actual = await vi.importActual("./online-indicator")
  return { ...actual, OnlineIndicator: () => <span role="status">Online</span> }
})

describe("OnlineIndicator", () => {
  test("renders online", () => {
    render(<OnlineIndicator />)
    expect(screen.getByRole("status")).toHaveTextContent("Online")
  })

  test("renders offline after a delay", async () => {
    render(<OnlineIndicator />)
    await new Promise((resolve) => setTimeout(resolve, 500))
    expect(screen.getByRole("status")).toBeInTheDocument()
  })
})
EOF

git add -A
git commit -qm "test(online-indicator): add component test"
