.DEFAULT_GOAL := build

.PHONY: build test test-build docs comments lint lint-fix format clean install install-tools sync-yaml

sync-yaml:
	mkdir -p ../workcorpus-kotlin/src/test/resources
	rm -f ../workcorpus-kotlin/src/test/resources/*.yaml
	cp Tests/WorkCorpusTests/Fixtures/*.yaml ../workcorpus-kotlin/src/test/resources/

build: lint test-build test docs
	swift build

test:
	swift test

test-build:
	swift build --build-tests

docs:
	swift package --allow-writing-to-directory .build/docc generate-documentation \
		--target WorkCorpus --output-path .build/docc \
		--warnings-as-errors \
		--transform-for-static-hosting \
		--hosting-base-path workcorpus-swift

comments:
	commentcensor .

lint: comments
	swiftlint --strict
	swift-format lint --strict --recursive Sources Tests Package.swift

lint-fix:
	$(MAKE) format

format:
	swift-format format --in-place --recursive Sources Tests Package.swift

clean:
	swift package clean
	rm -rf .build

install-tools:
	brew install swiftlint swift-format
	python3 -m pip install --quiet --upgrade git+https://github.com/botforge-pro/commentcensor.git

install:
	$(MAKE) install-tools
