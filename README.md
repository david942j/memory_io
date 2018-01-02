[![Build Status](https://travis-ci.org/david942j/memory_io.svg?branch=master)](https://travis-ci.org/david942j/memory_io)
[![Gem Version](https://badge.fury.io/rb/memory_io.svg)](https://badge.fury.io/rb/memory_io)
[![Maintainability](https://api.codeclimate.com/v1/badges/dc8da34c5a8ab0095530/maintainability)](https://codeclimate.com/github/david942j/memory_io/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/dc8da34c5a8ab0095530/test_coverage)](https://codeclimate.com/github/david942j/memory_io/test_coverage)
[![Inline docs](https://inch-ci.org/github/david942j/memory_io.svg?branch=master)](https://inch-ci.org/github/david942j/memory_io)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](http://choosealicense.com/licenses/mit/)

# Memory IO

Read/Write complicated structures in memory easily.

## Installation

Available on RubyGems.org!

```bash
$ gem install memory_io
```

## Usage

### Read Process's Memory
```ruby
require 'memory_io'

process = MemoryIO.attach(`pidof victim`.to_i)
puts process.read('heap', 4, as: :u64).map { |c| '0x%016x' % c }
# 0x0000000000000000
# 0x0000000000000021
# 0x00000000deadbeef
# 0x0000000000000000
#=> nil

process.read('heap+0x10', 4, as: :u8).map { |c| '0x%x' % c }
#=> ['0xef', '0xbe', '0xad', '0xde']

process.read('libc', 4)
#=> "\x7fELF"
```
