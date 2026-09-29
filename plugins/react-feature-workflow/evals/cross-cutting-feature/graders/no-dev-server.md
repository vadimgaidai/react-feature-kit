---
type: tool_used
tool: Bash
input_match: 'pnpm dev|npm run dev|yarn dev|\bvite\b(?! build)|vite preview'
min: 0
max: 0
---

The dev server is never started. The real session started it to "verify the tour in a browser", then went looking for the auth flow to get past the login; the skill now says typecheck is the whole verification.
