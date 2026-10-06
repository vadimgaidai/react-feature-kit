---
type: regex
target: last_message
pattern: 'comment\.api\.ts:\d+[\s\S]{0,600}?(useQuery|queryOptions|query layer|articleKeys|tanstack|sibling|react-query)'
flags: i
---

Q6: `useComments` hand-rolls fetch-in-effect while the sibling and the stack do it through TanStack Query. The finding names the project's way, not a universal rule.
