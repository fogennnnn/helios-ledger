# Contributing to Helios Ledger

Thank you for helping improve Helios! This guide covers how to contribute code, report bugs, and suggest features.

## Getting Started

1. **Fork** the repository on GitHub
2. **Clone** your fork: `git clone https://github.com/YOUR_USERNAME/helios-ledger.git`
3. **Install** dependencies: `pip install -r requirements.txt`
4. **Run tests** to confirm everything works: `pytest tests/ -v`

## Branching Convention

| Branch | Purpose |
|--------|---------|
| `main` | Stable releases |
| `develop` | Integration branch |
| `feat/*` | New features |
| `fix/*` | Bug fixes |
| `docs/*` | Documentation only |

## Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add batch record submission
fix: correct Merkle root after reorg
docs: update API reference for /verify
chore: bump cryptography to 42.x
```

## Pull Request Checklist

- [ ] All existing tests pass (`pytest tests/`)
- [ ] New tests cover new behaviour
- [ ] Docstrings updated
- [ ] `README.md` updated if the API changes
- [ ] No secrets or credentials in code

## Reporting Bugs

Open an [Issue](https://github.com/heliosledger/helios-ledger/issues/new?template=bug_report.md) with:

- Steps to reproduce
- Expected vs actual behaviour
- Python version and OS
- Relevant logs or tracebacks

## Suggesting Features

Open an [Issue](https://github.com/heliosledger/helios-ledger/issues/new?template=feature_request.md) with:

- The problem you're trying to solve
- Your proposed solution
- Any alternatives considered

## Code Style

- [Black](https://github.com/psf/black) for formatting (`black app/`)
- [isort](https://pycqa.github.io/isort/) for imports
- Type hints on all public functions

## License

By contributing you agree that your changes will be licensed under the [MIT License](../LICENSE).
