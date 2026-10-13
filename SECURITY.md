# Security Policy

If you discover a security issue, please do not open a public issue.

- Report privately to the maintainer.
- Include steps to reproduce and potential impact.
- We will acknowledge receipt within 48 hours and provide updates as triage progresses.

Do not commit secrets, PHI, tenant IDs, or plan files. Workloads authenticate
with user-assigned managed identities; connection strings do not belong in
this repository. See [docs/architecture/secrets.md](docs/architecture/secrets.md).
