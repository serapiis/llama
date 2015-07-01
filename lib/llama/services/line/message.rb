require 'date'

module Llama
  class LlamaMessage
    # @return [String]
    attr_reader :raw

    # @return [Time]
    attr_reader :time

    # @return [User] The user who sent this message
    attr_reader :user

    # @return [Room] The room in which this message was sent
    attr_reader :room

    def initialize(service, msg)
      @service = service

      @msg = msg
      @id = msg.id
      @raw = msg.text ? msg.text : ''
      @time = DateTime.strptime((msg.createdTime / 1000).to_s, '%s')
      @type = msg.toType
      @content_type = msg.contentType
      @content_preview = msg.contentPreview
      @content_metadata = msg.contentMetadata

      @sender = service.get_anything_by_id(msg.from)
      @receiver = service.get_anything_by_id(msg.to)

      if @sender.nil? or @receiver.nil?
        @service.refresh_contacts()
        @service.refresh_groups()
        @service.refresh_rooms()

        @sender = service.get_anything_by_id(msg.from)
        @receiver = service.get_anything_by_id(msg.to)
      end

      # message target
      @target = case @type
      when ToType::USER
        @user = @sender
        @room = @sender
        @sender
      when ToType::ROOM, ToType::GROUP
        @user = @sender
        @room = @receiver
        @receiver
      end

      if @user.class.to_s.include?('LineContact')
        @user.reload!
      end
    end

    def reply_user(type, content)
      if @user
        self.reply(type, content, @user)
      else
        false
      end
    end

    def reply(type, content, target=nil)
      target = @target if target.nil?
      if type == :text
        result = target.send_message(content)
      elsif type == :sticker
        result = target.send_sticker
      elsif type == :image
        method = content.include?('http') ? target.method(:send_image_url) : target.method(:send_image)
        result = method.call(content)
      end

      result
    end

    def has_content?
      @msg.hasContent
    end
  end
end