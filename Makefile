-include .env

all: test

test:
		forge test -vvvv

install:
		@echo "Should install lib/ and node_modules/"

script:
		@echo "Should run the script"
