#!/bin/bash

source ./.deploy
source ~/.bashrc

echo "Alright, let CI this project via this template https://git.drupalcode.org/project/drupalci_testbot/-/blob/production/composer.json"

export PATH="$PWD/vendor/bin:$PATH"
export PATH="$HOME/.composer/vendor/bin:$PATH"
export PATH="$HOME/.config/composer/vendor/bin:$PATH"

# Tests
phpcs --config-set installed_paths ~/.composer/vendor/drupal/coder/coder_sniffer
isFine=0
phpcs --standard=Drupal --extensions=php,module,inc,install,test,profile,theme ./web/modules/custom
isFine2=$?
[ "$isFine" == "0" ] && isFine="${isFine2}"
phpcs --standard=DrupalPractice --extensions=php,module,inc,install,test,profile,theme ./web/modules/custom
isFine2=$?
[ "$isFine" == "0" ] && isFine="${isFine2}"
phpcs --standard=Drupal --extensions=php,module,inc,install,test,profile,theme --report=diff ./web/modules/custom
phpcs --standard=DrupalPractice --extensions=php,module,inc,install,test,profile,theme --report=diff ./web/modules/custom

[[ "$DEPLOYANYWAY" == "1" || "$isFine" == "0" ]] && echo "Good to go to next step now" && exit 0
exit $isFine
