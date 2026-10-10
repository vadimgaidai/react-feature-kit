#!/bin/bash
# Fixture for the `routing-conventions` eval case. Runs in the empty workspace before
# the prompt (`--scaffold`).
set -eu

mkdir -p src/pages/orders

cat > package.json <<'EOF'
{
  "name": "eval-fixture",
  "private": true,
  "dependencies": { "react-router": "^6.0.0" },
  "scripts": { "typecheck": "echo 'typecheck: ok'" }
}
EOF

cat > src/pages/orders/orders-layout.tsx <<'EOF'
import { Outlet } from "react-router"

export const OrdersLayout = () => (
  <div>
    <header>Orders</header>
    <Outlet />
  </div>
)
EOF

git init -q
git config user.email eval@example.com
git config user.name Eval
git symbolic-ref HEAD refs/heads/main
git add -A
git commit -qm "baseline: orders layout"

git checkout -qb feature/orders-routing

cat > src/pages/orders/orders-layout.tsx <<'EOF'
import { Outlet, useNavigation } from "react-router"

export const OrdersLayout = () => {
  const navigation = useNavigation()

  if (navigation.state === "loading") {
    return null
  }

  return (
    <div>
      <header>Orders</header>
      <Outlet />
    </div>
  )
}
EOF

cat > src/pages/orders/orders-page.tsx <<'EOF'
import { useState } from "react"
import { useLoaderData, useNavigate, useSearchParams } from "react-router"

export const ordersLoader = async () => {
  const response = await fetch("/api/orders")
  return response.json()
}

export const OrdersPage = () => {
  const orders = useLoaderData() as { id: string }[]
  const [, setSearchParams] = useSearchParams()
  const [status, setStatus] = useState("all")
  const navigate = useNavigate()
  const [isNavigating, setIsNavigating] = useState(false)

  const applyStatus = (next: string) => {
    setStatus(next)
    setSearchParams({ status: next })
  }

  const goToDetails = async (id: string) => {
    setIsNavigating(true)
    await navigate(`/orders/${id}`)
    setIsNavigating(false)
  }

  return (
    <div>
      {isNavigating && <span>Loading…</span>}
      <select value={status} onChange={(event) => applyStatus(event.target.value)}>
        <option value="all">All</option>
        <option value="open">Open</option>
      </select>
      {orders.map((order) => (
        <button key={order.id} onClick={() => goToDetails(order.id)}>
          {order.id}
        </button>
      ))}
    </div>
  )
}
EOF

git add -A
git commit -qm "feat(orders): list page, status filter and loader"
