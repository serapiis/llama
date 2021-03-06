require 'thread'
require 'set'

module Llama
  class ListenerList
    include Enumerable

    def initialize
      @listeners = Hash.new { |h, k| h[k] = [] }
    end

    def register(listener)
      @listeners[listener.event] << listener
    end

    def unregister(*listeners)
      listeners.each do |listener|
        @listeners[listener.event].delete(listener)
      end
    end

    def find(type, msg = nil)
      if listeners = @listeners[type]
        if msg.nil?
          return listeners
        end

        listeners = listeners.select { |listener|
          msg.raw.match(listener.regex)
        }.group_by { |listener| listener.group }

        listeners.values_at(*(listeners.keys - [nil])).map(&:first) + (listeners[nil] || [])
      end
    end


    def dispatch(event, msg = nil, *args)
      threads = []

      if listeners = find(event, msg)
        already_run = Set.new
        listeners.each do |listener|
          next if already_run.include?(listener.block)

          captures = msg ? msg.raw.match(listener.regex).captures : []
          threads << listener.call(msg, captures, args)
        end
      end

      threads
    end

    def each(&block)
      @listeners.values.flatten.each(&block)
    end
  end
end