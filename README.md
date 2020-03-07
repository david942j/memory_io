[![Build Status](https://travis-ci.org/david942j/memory_io.svg?branch=master)](https://travis-ci.org/david942j/memory_io)
[![Gem Version](https://badge.fury.io/rb/memory_io.svg)](https://badge.fury.io/rb/memory_io)
[![Maintainability](https://api.codeclimate.com/v1/badges/dc8da34c5a8ab0095530/maintainability)](https://codeclimate.com/github/david942j/memory_io/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/dc8da34c5a8ab0095530/test_coverage)](https://codeclimate.com/github/david942j/memory_io/test_coverage)
[![Inline docs](https://inch-ci.org/github/david942j/memory_io.svg?branch=master)](https://inch-ci.org/github/david942j/memory_io)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](http://choosealicense.com/licenses/mit/)

# MemoryIO

Read/Write complicated structures in memory easily.

## Motivation

I usually need to dump a structure, say `string` in C++, from memory for debugging.
This is not hard if using gdb.
However, gdb doesn't support writing Ruby scripts
(unless you use [gdb-ruby](https://github.com/david942j/gdb-ruby), which has dependency of **MemoryIO**).
So I create this repo and want to make the debug procedure much easier.

This repository has two main goals:

1. To communicate with memory easily.
2. To collect all common structures for debugging/learning.

## Why

It's not hard to read/write a process's memory (simply open the file `/proc/$PID/mem`),
but it still worth to wrap it.

This repo also targets to collect all common structures, such as how to parse a C++/Rust/Python object from memory.
Therefore, **Pull Requests of adding new structures** are welcome :D

## Supported Platform

- Linux
- (TODO) Windows
- (TODO) MacOS

## Implemented Structures

Following is the list of supported structures.
Each type has a full-name and an alias. For example,

```ruby
require 'memory_io'

process = MemoryIO.attach(`pidof victim`.to_i)
# read a 64-bit unsigned integer
process.read(0x601000, 1, as: 'basic/u64')
# is equivalent to
process.read(0x601000, 1, as: :u64)
```

Go to [the online document](http://www.rubydoc.info/github/david942j/memory_io/master/MemoryIO/Types) for more details
of each type.

### BASIC
- `basic/u8`: An unsigned 8-bit integer. Also known as: `:u8`
- `basic/u16`: An unsigned 16-bit integer. Also known as: `:u16`
- `basic/u32`: An unsigned 32-bit integer. Also known as: `:u32`
- `basic/u64`: An unsigned 64-bit integer. Also known as: `:u64`
- `basic/s8`: A signed 8-bit integer. Also known as: `:s8`
- `basic/s16`: A signed 16-bit integer. Also known as: `:s16`
- `basic/s32`: A signed 32-bit integer. Also known as: `:s32`
- `basic/s64`: A signed 64-bit integer. Also known as: `:s64`
- `basic/float`: IEEE-754 32-bit floating number. Also known as: `:float`
- `basic/double`: IEEE-754 64-bit floating number. Also known as: `:double`

### CLANG
- `clang/c_str`: A null-terminated string. Also known as: `:c_str`

### CPP
- `cpp/string`: The `std::string` class in C++11. Also known as: `:string`


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

### Write Process's Memory
```ruby
require 'memory_io'

process = MemoryIO.attach('self') # Hack! Write memory of this process directly!
string = 'A' * 16
pos = string.object_id * 2 + 16
process.read(pos, 16)
#=> 'AAAAAAAAAAAAAAAA'

process.write(pos, 'memory_changed!!')
string
#=> 'memory_changed!!'
```

### Customize Read
```ruby
require 'memory_io'
process = MemoryIO.attach(`pidof victim`.to_i)

# An example that read a chunk of pt-malloc.
read_chunk = lambda do |stream|
  _prev_size = stream.read(8)
  size = (stream.read(8).unpack('Q').first & -16) - 8
  [size, stream.read(size)]
end
process.read('heap', 1, as: read_chunk)
#=> [24, "\xef\xbe\xad\xde\x00\x00...\x00"]
```

### Define Own Structure
```ruby
require 'memory_io'
process = MemoryIO.attach(`pidof victim`.to_i)

class MyType < MemoryIO::Types::Type
  def self.read(stream)
    self.new(stream.read(1))
  end

  # Define this if you need to 'write' to memory
  def self.write(stream, my_type)
    stream.write(my_type.val)
  end

  attr_accessor :val
  def initialize(val)
    @val = val
  end
end

# Use snake-case symbol.
process.read('libc', 4, as: :my_type)
#=> [#<MyType @val="\x7F">,
# #<MyType @val="E">,
# #<MyType @val="L">,
# #<MyType @val="F">]

process.write('libc', MyType.new('MEOW'), as: :my_type)

# See if memory changed
process.read('libc', 4)
#=> 'MEOW'
```

## Developing

### To Add a New Structure

TBA
