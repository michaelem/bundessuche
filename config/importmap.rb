# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin 'application'

pin_all_from 'app/javascript/components', under: 'components'
