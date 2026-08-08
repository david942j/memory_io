# frozen_string_literal: true

require 'memory_io/logger'

describe MemoryIO do
  after { described_class.logger = nil }

  it 'writes to stderr by default' do
    expect { described_class.logger.warn('meow') }.to output("[memory_io] WARN: meow\n").to_stderr
  end

  it 'can be redirected' do
    log = StringIO.new
    described_class.logger = Logger.new(log, progname: 'meow', formatter: MemoryIO::FORMATTER)
    described_class.logger.error('bad')
    expect(log.string).to eq "[meow] ERROR: bad\n"
  end

  it 'can be silenced' do
    described_class.logger.level = Logger::ERROR
    expect { described_class.logger.warn('quiet') }.to_not output.to_stderr
  end
end
