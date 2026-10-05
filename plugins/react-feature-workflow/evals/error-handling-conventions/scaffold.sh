#!/bin/bash
# Fixture for the `error-handling-conventions` eval case. Runs in the empty workspace
# before the prompt (`--scaffold`).
set -eu

mkdir -p src/entities/invoice/api src/entities/invoice/ui

cat > package.json <<'EOF'
{
  "name": "eval-fixture",
  "private": true,
  "scripts": { "typecheck": "echo 'typecheck: ok'" }
}
EOF

cat > src/entities/invoice/api/invoice.queries.ts <<'EOF'
import { queryOptions } from "@tanstack/react-query"

export const invoiceKeys = {
  all: ["invoice"] as const,
  detail: (id: string) => [...invoiceKeys.all, "detail", id] as const,
}

export const invoiceQueries = {
  detail: (id: string) => queryOptions({ queryKey: invoiceKeys.detail(id) }),
}
EOF

git init -q
git config user.email eval@example.com
git config user.name Eval
git symbolic-ref HEAD refs/heads/main
git add -A
git commit -qm "baseline: invoice queries"

git checkout -qb feature/invoice-panel

cat > src/entities/invoice/ui/invoice-panel.tsx <<'EOF'
import { useQuery } from "@tanstack/react-query"
import { invoiceQueries } from "../api/invoice.queries"

export function InvoicePanel({ invoiceId }: { invoiceId: string }) {
  try {
    const { data, isError } = useQuery(invoiceQueries.detail(invoiceId))

    if (isError) {
      return <p>Something went wrong. Please try again.</p>
    }

    const lineItems = data?.lineItems ?? []

    return (
      <ul>
        {lineItems.map((item) => (
          <li key={item.id}>{item.label}</li>
        ))}
      </ul>
    )
  } catch (error) {
    console.log("invoice panel failed", error)
    return null
  }
}
EOF

cat > src/entities/invoice/ui/invoice-actions.ts <<'EOF'
import { useMutation } from "@tanstack/react-query"
import { toast } from "sonner"

export function useResendInvoice(invoiceId: string) {
  const mutation = useMutation({
    mutationFn: () => fetch(`/invoices/${invoiceId}/resend`, { method: "POST" }),
    onError: () => {
      toast.error("Something went wrong")
    },
  })

  function handleResend() {
    mutation.mutate(undefined, {
      onError: () => {
        toast.error("Something went wrong")
      },
    })
  }

  return { handleResend }
}
EOF

git add -A
git commit -qm "feat(invoice): panel"
