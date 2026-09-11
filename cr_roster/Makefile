# cr_roster local dev helpers.
# Usage: `make -C cr_roster <target>`

PYTHON ?= python3

.PHONY: validate dump-json test clean help

help:
	@echo "Targets:"
	@echo "  validate   Run loader with schema validation enabled"
	@echo "  dump-json  Print providers as JSON to stdout"
	@echo "  test       Run pytest"
	@echo "  clean      Remove __pycache__"

validate:
	$(PYTHON) -c "from cr_roster import load_providers; load_providers(validate_schema=True); print('OK')"

dump-json:
	$(PYTHON) -c "import json; from cr_roster import load_providers; print(json.dumps(load_providers(), indent=2))"

test:
	$(PYTHON) -m pytest tests/ -v

clean:
	find . -type d -name __pycache__ -exec rm -rf {} +
