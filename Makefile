.PHONY: test build

test:
	bash scripts/setforge-test.sh

build:
	cd device/setforge-live && PYTHONPATH=../../tools python3 build/build_setforge.py
