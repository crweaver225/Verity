.PHONY: fmt

# ── Haskell builds ───────────────────────────────────────────────────────────
build-verity:
	cabal build

clean-verity:
	cabal clean

run-verity:
	cabal run

## Format all Haskell source files with stylish-haskell
fmt:
	find app src -name "*.hs" | xargs stylish-haskell -i
