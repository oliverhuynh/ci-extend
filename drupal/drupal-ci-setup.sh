#!/bin/bash

source ./.deploy
source ~/.bashrc

echo "Alright, let CI this project via this template https://git.drupalcode.org/project/drupalci_testbot/-/blob/production/composer.json"

export PATH="$PWD/vendor/bin:$PATH"
export PATH="$HOME/.composer/vendor/bin:$PATH"
export PATH="$HOME/.config/composer/vendor/bin:$PATH"

# Libs + builds
composer global require drupal/coder dealerdirect/phpcodesniffer-composer-installer
composer global require --dev phpspec/prophecy-phpunit:*
composer global require phpunit/phpunit:~9.0 --with-all-dependencies
# composer require squizlabs/php_codesniffer:^2.7

