[![Build Status](https://travis-ci.org/david942j/memory_io.svg?branch=master)](https://travis-ci.org/david942j/memory_io)
[![Maintainability](https://api.codeclimate.com/v1/badges/dc8da34c5a8ab0095530/maintainability)](https://codeclimate.com/github/david942j/memory_io/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/dc8da34c5a8ab0095530/test_coverage)](https://codeclimate.com/github/david942j/memory_io/test_coverage)
[![Inline docs](https://inch-ci.org/github/david942j/memory_io.svg?branch=master)](https://inch-ci.org/github/david942j/memory_io)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](http://choosealicense.com/licenses/mit/)

# Memory IO

Read/Write complicated structures in memory easily.

## Installation

TBD

## Usage

```
require 'memory_io'

io = MemoryIO::IO.new(File.open('/proc/self/mem'))
```
