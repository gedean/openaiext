module OpenAIExt
  class Agent
    extend OpenAI
    
    attr_reader :assistant, :thread, :instructions, :vector_store_id

    def initialize(assistant_id: nil, thread_id: nil, thread_instructions: nil, vector_store_id: nil)
      @openai_client = OpenAI::Client.new

      assistant_id ||= ENV.fetch('OPENAI_ASSISTANT_ID')
      @assistant = @openai_client.assistants.retrieve(id: assistant_id)

      thread_params = {}

      # Only one vector store can be attached, according to the OpenAI API documentation
      @vector_store_id = vector_store_id
      thread_params = { tool_resources: { file_search: { vector_store_ids: [vector_store_id] } } } if @vector_store_id

      thread_id ||= @openai_client.threads.create(parameters: thread_params)['id']
      @thread = @openai_client.threads.retrieve(id: thread_id)

      @instructions = thread_instructions || @assistant['instructions']
    end

    def add_message(text, role: 'user') = @openai_client.messages.create(thread_id: @thread['id'], parameters: { role: role, content: text })
    def messages = @openai_client.messages.list(thread_id: @thread['id'])
    def last_message = messages['data'].first['content'].first['text']['value']
    def runs = @openai_client.runs.list(thread_id: @thread['id'])

    def run(instructions: nil, additional_instructions: nil, additional_message: nil, model: nil, tool_choice: nil)
      params = { assistant_id: @assistant['id'] }

      params[:instructions] = instructions || @instructions
      params[:additional_instructions] = additional_instructions unless additional_instructions.nil?
      params[:tool_choice] = tool_choice unless tool_choice.nil?

      params[:additional_messages] = [{ role: :user, content: additional_message }] unless additional_message.nil?

      params[:model] = OpenAIExt::Model.select(model) || @assistant['model']

      run_id = @openai_client.runs.create(thread_id: @thread['id'], parameters: params)['id']

      loop do
        response = @openai_client.runs.retrieve(id: run_id, thread_id: @thread['id'])

        case response['status']
        when 'queued', 'in_progress', 'cancelling'
          puts 'Status: Waiting AI Processing finish'
          sleep 1
        when 'completed'
          puts last_message
          break
        when 'requires_action'
          # Handle tool calls (see below)
        when 'cancelled', 'failed', 'expired'
          puts response['last_error'].inspect
          break # or `exit`
        else
          puts "Unknown status response: #{status}"
        end
      end
    end
  end
end
