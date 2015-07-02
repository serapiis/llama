module Llama
  module Plugin
    module ClassMethods

      attr_reader :matchers

      def self.extended(by)
        by.instance_exec do
          @matchers = {}
        end
      end

      def match(pattern, dest=:execute)
        if pattern.class == String
          pattern = Regexp.escape(pattern)
          pattern = Regexp.new("^#{pattern}$")
        end
        @matchers[pattern] = dest
      end
    end

    module InstanceMethods
      include Llama::Logging
      attr_reader :threads

      def initialize(bot=nil)
        @bot = bot

        self.init if self.class.method_defined? :init
      end

      def dispatch(msg)
      EM.next_tick do
          self.class.matchers.each do |pattern, dest|
            unless self.class.method_defined? dest
              puts "method does not exist"
              break
            end

            match = msg.raw.match(pattern)
            next unless match
            captures = match.captures ||= []
            self.send(dest, msg, captures)
          end
        end
      end

      def unregister
        @bot.plugins.unregister(self)
      end

      def stop(force=false)
        @threads.each do |thread|
          thread.join(10) unless force
          thread.kill
        end
      end
    end

    # @api private
    def self.included(by)
      by.send(:include, InstanceMethods)
      by.extend(ClassMethods)
    end
  end
end
